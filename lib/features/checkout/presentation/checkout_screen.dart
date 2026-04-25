import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../core/models/listing_model.dart';
import '../../../core/models/pricing_result_model.dart';
import '../../../core/providers/listings_provider.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/pricing_engine_service.dart';
import '../../../core/services/mercadopago_service.dart';
import '../../../shared/widgets/availability_calendar.dart';
import '../../../shared/widgets/time_slot_picker.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/error_handler.dart';
import '../../../l10n/app_localizations.dart';
import 'payment_webview_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final String listingId;
  const CheckoutScreen({super.key, required this.listingId});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  DateTime? _checkIn;
  DateTime? _checkOut;
  DateTime? _selectedDate; // for hours/full_day
  int _guests = 1;
  bool _isBooking = false;
  PricingResult? _pricingResult;
  final Set<String> _selectedTimeSlots = {};
  final Map<String, String> _slotEndTimes = {};

  /// Host's booking count (for promotional pricing)
  int? _hostBookingsCount;

  /// Effective fee rate: 1% if host has < 5 bookings, 7% otherwise
  double get _feeRate =>
      PricingEngineService.getEffectiveFeeRate(_hostBookingsCount ?? 999);

  bool get _isPromoRate =>
      (_hostBookingsCount ?? 999) < PricingEngineService.promoBookingThreshold;

  @override
  void initState() {
    super.initState();
    _loadHostPromoStatus();
  }

  /// Fetch host booking count to determine if promotional 1% applies
  Future<void> _loadHostPromoStatus() async {
    try {
      final data = ref.read(listingDetailProvider(widget.listingId)).value;
      if (data == null) {
        // Data not loaded yet; will retry when build triggers
        Future.delayed(const Duration(milliseconds: 500), _loadHostPromoStatus);
        return;
      }
      final listing = Listing.fromJson(data);
      final count = await DatabaseService.getHostBookingsCount(listing.hostId);
      if (mounted) {
        setState(() {
          _hostBookingsCount = count;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hostBookingsCount = 999; // Fallback: standard rate
        });
      }
    }
  }

  int get _nights {
    if (_checkIn == null || _checkOut == null) return 1;
    return _checkOut!.difference(_checkIn!).inDays.clamp(1, 365);
  }

  /// Number of hour-blocks selected (each slot = 1 block of N hours)
  int _blockCount(Listing l) => _selectedTimeSlots.length;

  /// Total hours = blocks × blockHours
  int _totalHours(Listing l) {
    final bh = l.blockHours > 0 ? l.blockHours : 1;
    return _selectedTimeSlots.length * bh;
  }

  String _fmt(DateTime? dt) {
    final l = AppLocalizations.of(context);
    if (dt == null) return l.checkoutSelectPlaceholder;
    final m = ['', l.monthAbbrJan, l.monthAbbrFeb, l.monthAbbrMar, l.monthAbbrApr, l.monthAbbrMay, l.monthAbbrJun, l.monthAbbrJul, l.monthAbbrAug, l.monthAbbrSep, l.monthAbbrOct, l.monthAbbrNov, l.monthAbbrDec];
    return '${dt.day} ${m[dt.month]} ${dt.year}';
  }

  String _unitLabel(String u) {
    final l = AppLocalizations.of(context);
    switch (u) {
      case 'night': return l.checkoutUnitNight;
      case 'hour': return l.checkoutUnitHour;
      case 'session': return l.checkoutUnitSession;
      case 'person': return l.checkoutUnitPerson;
      default: return u;
    }
  }

  /// Whether this listing charges per person (affects quantity calculation)
  bool _isPerPerson(Listing l) => l.priceUnit == 'person';

  /// Whether this listing uses per-person pricing AND hourly mode
  /// In this case, only 1 time slot can be selected (1 session at a time)
  bool _isSingleSlotMode(Listing l) =>
      _isPerPerson(l) && l.rentalMode == 'hours';

  /// Calculate the correct subtotal based on mode, units, and pricing type
  /// For hours mode: price is per BLOCK (e.g. $35/block of 2h), not per individual hour
  double _calcSubtotal(Listing l) {
    final base = l.basePrice ?? 0;
    final mode = l.rentalMode;
    final perPerson = _isPerPerson(l);
    final guestMultiplier = perPerson ? _guests : 1;

    if (mode == 'hours') {
      // Each selected time slot = 1 block at base price
      final blocks = _blockCount(l);
      final qty = blocks > 0 ? blocks : 1;
      return base * qty * guestMultiplier;
    } else if (mode == 'full_day') {
      return base * 1 * guestMultiplier;
    } else {
      return base * _nights * guestMultiplier;
    }
  }

  /// Calculate service fee with dynamic rate and $90.000 CLP cap
  /// Uses 1% for promo hosts (< 5 bookings), 7% standard, capped at $90.000 CLP
  double _calcServiceFee(double subtotal, double cleaningFee) {
    final rate = _feeRate;
    final raw = (subtotal + cleaningFee) * rate;
    return raw > PricingEngineService.maxFeeCap
        ? PricingEngineService.maxFeeCap
        : raw;
  }

  Future<void> _calcPricing({Listing? listing}) async {
    final data = ref.read(listingDetailProvider(widget.listingId)).value;
    if (data == null) return;
    final l = listing ?? Listing.fromJson(data);

    final mode = l.rentalMode;
    final basePrice = l.basePrice ?? 0;
    final cleaningFee = mode == 'hours' ? 0.0 : l.cleaningFee;

    // Calculate units based on mode (for hours: 1 unit = 1 block)
    int units;
    if (mode == 'hours') {
      units = _blockCount(l) > 0 ? _blockCount(l) : 1;
    } else if (mode == 'full_day') {
      units = 1;
    } else {
      if (_checkIn == null || _checkOut == null) return;
      units = _nights;
    }

    // For per-person pricing, multiply by guests
    final perPerson = _isPerPerson(l);
    final effectiveBase = perPerson ? basePrice * _guests : basePrice;

    // Always use client-side preview for accurate calculation
    // The RPC doesn't understand time slots or per-person multipliers correctly
    final p = PricingEngineService.previewPricing(
      basePrice: effectiveBase,
      cleaningFee: cleaningFee,
      nights: units,
      guestFeeRate: _feeRate,
      pricingModel: _isPromoRate ? 'PROMO_1_PERCENT' : 'STANDARD_7_CAP99',
    );
    if (mounted) setState(() => _pricingResult = p);
  }

  Future<void> _confirm(Listing listing) async {
    Haptics.medium();
    final l = AppLocalizations.of(context);
    final mode = listing.rentalMode;

    if (mode == 'nights' && (_checkIn == null || _checkOut == null)) {
      _snack(l.checkoutSelectDatesFirst, isError: true);
      return;
    }
    if (mode == 'full_day' && _selectedDate == null) {
      _snack(l.checkoutSelectDay, isError: true);
      return;
    }
    if (mode == 'hours' && (_selectedDate == null || _selectedTimeSlots.isEmpty)) {
      _snack(l.checkoutSelectDateAndSlots, isError: true);
      return;
    }

    setState(() => _isBooking = true);
    try {
      final effectiveCheckIn = mode == 'nights'
          ? _checkIn!
          : _selectedDate!;
      final effectiveCheckOut = mode == 'nights'
          ? _checkOut!
          : _selectedDate!.add(const Duration(days: 1));

      // Use helper methods for correct pricing (same as display)
      final sub = _calcSubtotal(listing);
      final clean = mode == 'hours' ? 0.0 : listing.cleaningFee;
      final fee = _calcServiceFee(sub, clean);
      final total = sub + clean + fee;

      // Validate pricing integrity before submitting
      final units = mode == 'hours'
          ? _blockCount(listing)
          : (mode == 'full_day' ? 1 : _nights);
      final isValid = PricingEngineService.validatePricing(
        basePrice: listing.basePrice ?? 0,
        submittedSubtotal: sub,
        submittedFee: fee,
        units: units,
        guests: _guests,
        isPerPerson: _isPerPerson(listing),
        feeRate: _feeRate,
      );
      if (!isValid) {
        if (mounted) _snack(l.checkoutCalcError, isError: true);
        setState(() => _isBooking = false);
        return;
      }

      final timeSlots = _selectedTimeSlots.map((start) => {
        'start_time': start,
        'end_time': _slotEndTimes[start] ?? '',
      }).toList();

      final sortedSlots = List<String>.from(_selectedTimeSlots)..sort();

      final bookingData = {
        'listing_id': listing.id,
        'host_id': listing.hostId,
        'guest_id': AuthService.currentUser!.id,
        'check_in': effectiveCheckIn.toIso8601String(),
        'check_out': effectiveCheckOut.toIso8601String(),
        'guests_count': _guests,
        'base_total': sub,
        'cleaning_fee': clean,
        'service_fee': fee,
        'total': total,
        'status': listing.instantBooking ? 'confirmed' : 'pending',
        'payment_status': 'pending',
        'rental_mode': mode,
        if (mode == 'hours') ...{
          'time_slots': timeSlots,
          'booking_date': _selectedDate!.toIso8601String().split('T')[0],
          'start_time': sortedSlots.isNotEmpty ? sortedSlots.first : null,
          'end_time': sortedSlots.isNotEmpty ? _slotEndTimes[sortedSlots.last] : null,
          'duration_hours': _totalHours(listing).toDouble(),
          'block_hours': listing.blockHours,
          'block_count': _blockCount(listing),
        },
      };

      // Step 1: Create booking with payment_status = 'pending'
      final result = await DatabaseService.createBookingWithCheck(bookingData);

      if (result == null) {
        if (mounted) _snack(l.checkoutDatesUnavailable, isError: true);
        return;
      }

      final bookingId = result['id'] as String;

      // Step 2: If Mercado Pago is configured, process real payment
      if (MercadoPagoService.isConfigured) {
        await _processPayment(
          listing: listing,
          bookingId: bookingId,
          total: total,
          serviceFee: fee,
        );
      } else {
        // Fallback: no payment provider → confirm directly (dev mode)
        if (mounted) {
          _snack(l.checkoutDevMode);
          await Future.delayed(const Duration(milliseconds: 600));
          if (mounted) context.pushReplacement('/booking-confirmed');
        }
      }
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  /// Process payment via Mercado Pago Checkout Pro.
  ///
  /// 1. Creates MP preference with booking details
  /// 2. Opens WebView for user to pay
  /// 3. Handles result: approved → update booking, rejected → show error
  Future<void> _processPayment({
    required Listing listing,
    required String bookingId,
    required double total,
    required double serviceFee,
  }) async {
    try {
      // Create Mercado Pago preference
      final userEmail = AuthService.currentUser?.email ?? 'guest@atrio.app';
      final preference = await MercadoPagoService.createPreference(
        title: 'Reserva: ${listing.title}',
        description: '${listing.city ?? 'Atrio'} - ${listing.type}',
        amount: total,
        payerEmail: userEmail,
        externalReference: bookingId,
      );

      // Store preference ID in booking
      await DatabaseService.updateBookingPaymentStatus(
        bookingId,
        paymentStatus: 'pending',
        mpPreferenceId: preference.id,
      );

      if (!mounted) return;

      // Open Mercado Pago Checkout in WebView
      final paymentResult = await Navigator.of(context).push<PaymentResult>(
        MaterialPageRoute(
          builder: (_) => PaymentWebViewScreen(
            checkoutUrl: preference.initPoint,
            bookingId: bookingId,
          ),
        ),
      );

      if (!mounted) return;

      if (paymentResult == null || paymentResult.isCancelled) {
        // User closed the WebView without paying
        _snack(
          AppLocalizations.of(context).checkoutPaymentPending,
          isError: false,
        );
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) context.pushReplacement('/guest/bookings');
        return;
      }

      if (paymentResult.isApproved) {
        await _handlePaymentApproved(
          bookingId: bookingId,
          hostId: listing.hostId,
          total: total,
          serviceFee: serviceFee,
          paymentId: paymentResult.paymentId,
        );
      } else if (paymentResult.isPending) {
        await _handlePaymentPending(bookingId, paymentResult.paymentId);
      } else {
        await _handlePaymentRejected(bookingId, paymentResult);
      }
    } on MpException catch (e) {
      if (mounted) {
        _snack(AppLocalizations.of(context).checkoutPaymentError(e.message), isError: true);
      }
    }
  }

  /// Payment approved → update booking, create transaction, show success.
  Future<void> _handlePaymentApproved({
    required String bookingId,
    required String hostId,
    required double total,
    required double serviceFee,
    String? paymentId,
  }) async {
    // Verify with MP API if we have a payment ID
    if (paymentId != null && paymentId.isNotEmpty) {
      try {
        final status = await MercadoPagoService.getPaymentStatus(paymentId);
        if (!status.isApproved) {
          // MP says it's not really approved - handle accordingly
          if (status.isPending) {
            await _handlePaymentPending(bookingId, paymentId);
            return;
          }
          if (mounted) {
            _snack(AppLocalizations.of(context).checkoutPaymentNotApproved(status.statusLabel),
                isError: true);
          }
          return;
        }
      } catch (_) {
        // Verification failed but redirect said approved - trust redirect
      }
    }

    // Update booking payment status to paid
    await DatabaseService.updateBookingPaymentStatus(
      bookingId,
      paymentStatus: 'paid',
      mpPaymentId: paymentId,
    );

    // Create transaction records (host earning + platform fee)
    await DatabaseService.createPaymentTransaction(
      bookingId: bookingId,
      hostId: hostId,
      amount: total,
      serviceFee: serviceFee,
      mpPaymentId: paymentId,
    );

    if (mounted) {
      _snack(AppLocalizations.of(context).checkoutPaymentApproved);
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) context.pushReplacement('/booking-confirmed');
    }
  }

  /// Payment pending → update status, redirect to bookings.
  Future<void> _handlePaymentPending(
      String bookingId, String? paymentId) async {
    await DatabaseService.updateBookingPaymentStatus(
      bookingId,
      paymentStatus: 'pending',
      mpPaymentId: paymentId,
    );

    if (mounted) {
      _snack(AppLocalizations.of(context).checkoutPaymentInProcess);
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) context.pushReplacement('/guest/bookings');
    }
  }

  /// Payment rejected → show error, allow retry.
  Future<void> _handlePaymentRejected(
      String bookingId, PaymentResult result) async {
    await DatabaseService.updateBookingPaymentStatus(
      bookingId,
      paymentStatus: 'failed',
      mpPaymentId: result.paymentId,
    );

    if (mounted) {
      final l = AppLocalizations.of(context);
      // Try to get specific rejection reason
      String errorMsg = l.checkoutPaymentRejected;
      if (result.paymentId != null && result.paymentId!.isNotEmpty) {
        try {
          final status =
              await MercadoPagoService.getPaymentStatus(result.paymentId!);
          if (status.rejectionReason != null) {
            errorMsg = status.rejectionReason!;
          }
        } catch (_) {}
      }

      if (!mounted) return;
      _snack(errorMsg, isError: true);

      // Show retry dialog
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      _showRetryDialog(bookingId);
    }
  }

  void _showRetryDialog(String bookingId) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: AtrioColors.error),
            const SizedBox(width: 10),
            Text(l.checkoutRejectedTitle,
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(l.checkoutRejectedDesc),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.pushReplacement('/guest/bookings');
            },
            child: Text(
              l.checkoutGoToBookings,
              style: GoogleFonts.inter(color: AtrioColors.guestTextSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Stay on checkout to retry (booking already exists)
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AtrioColors.neonLime,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l.checkoutRetryBtn,
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        color: isError ? Colors.white : Colors.black,
      )),
      backgroundColor: isError ? AtrioColors.error : AtrioColors.neonLime,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final listingAsync = ref.watch(listingDetailProvider(widget.listingId));

    return listingAsync.when(
      data: (data) {
        if (data == null) {
          return Scaffold(
            backgroundColor: AtrioColors.guestBackground,
            appBar: AppBar(backgroundColor: AtrioColors.guestBackground, elevation: 0),
            body: Center(child: Text(l.checkoutNotFound)),
          );
        }
        return _page(Listing.fromJson(data));
      },
      loading: () => const Scaffold(
        backgroundColor: AtrioColors.guestBackground,
        body: Center(child: CircularProgressIndicator(color: AtrioColors.neonLimeDark, strokeWidth: 2.5)),
      ),
      error: (_, _) => Scaffold(
        backgroundColor: AtrioColors.guestBackground,
        appBar: AppBar(backgroundColor: AtrioColors.guestBackground, elevation: 0),
        body: Center(child: Text(l.checkoutLoadError)),
      ),
    );
  }

  Widget _page(Listing listing) {
    final l = AppLocalizations.of(context);
    final mode = listing.rentalMode;
    final base = listing.basePrice ?? 0;
    final blockH = listing.blockHours > 0 ? listing.blockHours : 1;
    final blocks = mode == 'hours' ? (_blockCount(listing) > 0 ? _blockCount(listing) : 1) : 1;
    final totalH = mode == 'hours' ? blocks * blockH : 0;

    // Always use helper methods for correct pricing (ignores potentially stale _pricingResult)
    final sub = _calcSubtotal(listing);
    final clean = mode == 'hours' ? 0.0 : listing.cleaningFee;
    final fee = _calcServiceFee(sub, clean);
    final total = sub + clean + fee;
    final feePercent = (_feeRate * 100).toStringAsFixed(0);
    final feeLabel = '$feePercent%';
    final host = listing.hostData;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    String modeLabel;
    String unitSuffix;
    switch (mode) {
      case 'hours':
        modeLabel = blockH > 1 ? l.checkoutModeHoursBlock(blockH) : l.checkoutModeHours;
        unitSuffix = l.checkoutUnitHoursBlocks(totalH, blocks);
        break;
      case 'full_day':
        modeLabel = l.checkoutModeFullDay;
        unitSuffix = l.checkoutUnitOneDay;
        break;
      default:
        modeLabel = l.checkoutModeNights;
        unitSuffix = l.checkoutNightsBadge(_nights);
    }

    return Scaffold(
      backgroundColor: AtrioColors.guestBackground,
      appBar: AppBar(
        backgroundColor: AtrioColors.guestBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AtrioColors.guestTextPrimary),
        ),
        title: Text(
          l.checkoutConfirmTitle,
          style: AtrioTypography.headingSmall.copyWith(color: AtrioColors.guestTextPrimary),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Listing card ───
                  _buildListingCard(listing, base),
                  const SizedBox(height: 16),

                  // ─── Rental mode badge ───
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AtrioColors.neonLime.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          mode == 'hours' ? Icons.access_time : mode == 'full_day' ? Icons.today : Icons.nightlight_round,
                          size: 16, color: AtrioColors.neonLimeDark,
                        ),
                        const SizedBox(width: 6),
                        Text(modeLabel, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AtrioColors.neonLimeDark)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── Host info ───
                  if (host != null) ...[
                    _buildHostInfo(host),
                    const SizedBox(height: 20),
                    const Divider(height: 1, color: AtrioColors.guestCardBorder),
                    const SizedBox(height: 20),
                  ],

                  // ─── Date/Time selection (mode-specific) ───
                  if (mode == 'nights') ...[
                    Text(l.checkoutDatesLabel, style: AtrioTypography.headingSmall.copyWith(color: AtrioColors.guestTextPrimary)),
                    const SizedBox(height: 12),
                    AvailabilityCalendar(
                      listingId: widget.listingId,
                      rentalMode: mode,
                      selectedCheckIn: _checkIn,
                      selectedCheckOut: _checkOut,
                      onRangeSelected: (start, end) {
                        setState(() {
                          _checkIn = start;
                          _checkOut = end;
                          _pricingResult = null;
                        });
                        _calcPricing(listing: listing);
                      },
                    ),
                    if (_checkIn != null && _checkOut != null) ...[
                      const SizedBox(height: 12),
                      _buildDateSummary(listing),
                    ],
                  ] else if (mode == 'full_day') ...[
                    Text(l.checkoutSelectDayLabel, style: AtrioTypography.headingSmall.copyWith(color: AtrioColors.guestTextPrimary)),
                    const SizedBox(height: 12),
                    AvailabilityCalendar(
                      listingId: widget.listingId,
                      rentalMode: mode,
                      selectedDate: _selectedDate,
                      onDateTap: (date) {
                        setState(() {
                          _selectedDate = date;
                          _pricingResult = null;
                        });
                        _calcPricing(listing: listing);
                      },
                    ),
                    if (_selectedDate != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AtrioColors.neonLime.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.today, size: 18, color: AtrioColors.neonLimeDark),
                            const SizedBox(width: 8),
                            Text(_fmt(_selectedDate), style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ] else ...[
                    // Hours mode
                    Text(l.checkoutSelectDateLabel, style: AtrioTypography.headingSmall.copyWith(color: AtrioColors.guestTextPrimary)),
                    const SizedBox(height: 12),
                    AvailabilityCalendar(
                      listingId: widget.listingId,
                      rentalMode: mode,
                      selectedDate: _selectedDate,
                      onDateTap: (date) {
                        setState(() {
                          _selectedDate = date;
                          _selectedTimeSlots.clear();
                          _slotEndTimes.clear();
                          _pricingResult = null;
                        });
                      },
                    ),
                    if (_selectedDate != null) ...[
                      const SizedBox(height: 20),
                      if (_isSingleSlotMode(listing))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            l.checkoutSelectOneSlot,
                            style: GoogleFonts.inter(fontSize: 12, color: AtrioColors.guestTextSecondary, fontStyle: FontStyle.italic),
                          ),
                        ),
                      TimeSlotPicker(
                        listingId: widget.listingId,
                        selectedDate: _selectedDate!,
                        availableFrom: listing.availableFrom ?? '09:00',
                        availableUntil: listing.availableUntil ?? '22:00',
                        slotDurationMinutes: (listing.blockHours > 0 ? listing.blockHours : 1) * 60,
                        selectedSlots: _selectedTimeSlots,
                        onSlotToggle: (start, end, selected) {
                          setState(() {
                            if (selected) {
                              // Per-person + hours = single slot only (one session)
                              if (_isSingleSlotMode(listing)) {
                                _selectedTimeSlots.clear();
                                _slotEndTimes.clear();
                              }
                              _selectedTimeSlots.add(start);
                              _slotEndTimes[start] = end;
                            } else {
                              _selectedTimeSlots.remove(start);
                              _slotEndTimes.remove(start);
                            }
                            _pricingResult = null;
                          });
                          if (_selectedTimeSlots.isNotEmpty) {
                            _calcPricing(listing: listing);
                          }
                        },
                      ),
                    ],
                  ],

                  const SizedBox(height: 20),

                  // ─── Guests section ───
                  _buildGuestsSection(listing),
                  const SizedBox(height: 24),

                  // ─── Price breakdown ───
                  Text(l.checkoutPriceSummary, style: AtrioTypography.headingSmall.copyWith(color: AtrioColors.guestTextPrimary)),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AtrioColors.guestSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AtrioColors.guestCardBorder),
                    ),
                    child: Column(
                      children: [
                        _priceRow(
                          _isPerPerson(listing)
                              ? (mode == 'hours'
                                  ? l.checkoutPriceBasePersonHours(base.toCLP, _guests, blocks)
                                  : l.checkoutPriceBasePerson(base.toCLP, _guests))
                              : mode == 'hours'
                                  ? l.checkoutPriceBaseHoursSimple(base.toCLP, blocks, blockH)
                                  : l.checkoutPriceBaseUnit(base.toCLP, unitSuffix),
                          sub,
                        ),
                        if (clean > 0) _priceRow(l.checkoutCleaning, clean),
                        _priceRow(
                          _isPromoRate
                              ? l.checkoutPromoFeeLabel(feeLabel)
                              : (fee >= 90000
                                  ? l.checkoutServiceFeeCapped(feeLabel)
                                  : l.checkoutServiceFeeLabel(feeLabel)),
                          fee,
                        ),
                        if (_isPromoRate)
                          Padding(
                            padding: const EdgeInsets.only(top: 6, bottom: 2),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AtrioColors.neonLime.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.local_offer, size: 14, color: AtrioColors.neonLimeDark),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      l.checkoutPromoRemaining(PricingEngineService.promoBookingThreshold - (_hostBookingsCount ?? 0)),
                                      style: GoogleFonts.inter(fontSize: 11, color: AtrioColors.neonLimeDark, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(height: 1, color: AtrioColors.guestCardBorder),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(l.bookingTotal, style: AtrioTypography.headingSmall.copyWith(color: AtrioColors.guestTextPrimary)),
                            Text(total.toCLP, style: AtrioTypography.priceLarge.copyWith(color: AtrioColors.guestTextPrimary)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ─── Payment method (Mercado Pago) ───
                  Text(l.checkoutPaymentMethodTitle, style: AtrioTypography.headingSmall.copyWith(color: AtrioColors.guestTextPrimary)),
                  const SizedBox(height: 12),
                  _buildPaymentMethodCard(),

                  const SizedBox(height: 24),

                  // ─── Cancellation policy ───
                  _buildCancellationPolicy(listing),

                  const SizedBox(height: 16),

                  // ─── Security (MP branding) ───
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline, size: 13, color: Color(0xFF009EE3)),
                      const SizedBox(width: 6),
                      Text(
                        l.checkoutPaySecureBadge,
                        style: GoogleFonts.inter(fontSize: 10, color: AtrioColors.guestTextTertiary, letterSpacing: 1, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.verified_user_outlined, size: 11, color: Color(0xFF009EE3)),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ─── Bottom bar ───
          Container(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + bottomPadding),
            decoration: BoxDecoration(
              color: AtrioColors.guestSurface,
              border: const Border(top: BorderSide(color: AtrioColors.guestCardBorder)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, -4)),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: MaterialButton(
                onPressed: _isBooking ? null : () => _confirm(listing),
                color: AtrioColors.neonLime,
                disabledColor: AtrioColors.neonLime.withValues(alpha: 0.4),
                elevation: 0, highlightElevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: _isBooking
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_outline, size: 16, color: Colors.black54),
                          const SizedBox(width: 6),
                          Text(
                            l.checkoutPayAmount(total.toCLP),
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Sub-widgets ───

  Widget _buildListingCard(Listing listing, double base) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AtrioColors.guestSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AtrioColors.guestCardBorder),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 80, height: 80,
              child: listing.images.isNotEmpty
                  ? CachedNetworkImage(imageUrl: listing.images.first, fit: BoxFit.cover)
                  : Container(color: AtrioColors.guestSurfaceVariant, child: const Icon(Icons.image, color: AtrioColors.guestTextTertiary)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(listing.title, style: AtrioTypography.labelLarge.copyWith(color: AtrioColors.guestTextPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                if (listing.city != null)
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: AtrioColors.guestTextTertiary),
                    const SizedBox(width: 3),
                    Text(listing.city!, style: AtrioTypography.caption.copyWith(color: AtrioColors.guestTextSecondary)),
                  ]),
                const SizedBox(height: 6),
                Row(children: [
                  Text(base.toCLP, style: AtrioTypography.priceMedium.copyWith(color: AtrioColors.guestTextPrimary)),
                  Text(' / ${_unitLabel(listing.priceUnit)}', style: AtrioTypography.caption.copyWith(color: AtrioColors.guestTextSecondary)),
                  const Spacer(),
                  if (listing.rating > 0) ...[
                    const Icon(Icons.star_rounded, size: 14, color: AtrioColors.ratingGold),
                    const SizedBox(width: 3),
                    Text(listing.rating.toStringAsFixed(1), style: AtrioTypography.caption.copyWith(fontWeight: FontWeight.w600, color: AtrioColors.guestTextPrimary)),
                  ],
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostInfo(Map<String, dynamic> host) {
    final l = AppLocalizations.of(context);
    return Row(children: [
      CircleAvatar(
        radius: 22,
        backgroundColor: AtrioColors.neonLime.withValues(alpha: 0.2),
        backgroundImage: host['photo_url'] != null ? CachedNetworkImageProvider(host['photo_url'] as String) : null,
        child: host['photo_url'] == null ? const Icon(Icons.person, size: 22, color: AtrioColors.neonLimeDark) : null,
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(host['display_name'] as String? ?? l.checkoutHostFallback, style: AtrioTypography.labelMedium.copyWith(color: AtrioColors.guestTextPrimary)),
          if (host['is_verified'] == true) ...[const SizedBox(width: 5), const Icon(Icons.verified, size: 16, color: AtrioColors.neonLimeDark)],
        ]),
        Text(l.checkoutHostLabel, style: AtrioTypography.caption.copyWith(color: AtrioColors.guestTextTertiary)),
      ])),
    ]);
  }

  Widget _buildDateSummary(Listing listing) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AtrioColors.guestSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AtrioColors.neonLimeDark.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.checkoutCheckInLabel, style: AtrioTypography.caption.copyWith(color: AtrioColors.guestTextTertiary)),
          const SizedBox(height: 4),
          Text(_fmt(_checkIn), style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
        ])),
        Container(width: 1, height: 36, color: AtrioColors.guestCardBorder),
        Expanded(child: Padding(padding: const EdgeInsets.only(left: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.checkoutCheckOutLabel, style: AtrioTypography.caption.copyWith(color: AtrioColors.guestTextTertiary)),
          const SizedBox(height: 4),
          Text(_fmt(_checkOut), style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
        ]))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: AtrioColors.neonLime, borderRadius: BorderRadius.circular(10)),
          child: Text(l.checkoutNightsBadge(_nights), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black)),
        ),
      ]),
    );
  }

  Widget _buildGuestsSection(Listing listing) {
    final l = AppLocalizations.of(context);
    final isPeople = listing.type == 'experience' || listing.type == 'service';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
      isPeople ? l.checkoutPeople : l.checkoutGuests,
      style: AtrioTypography.headingSmall.copyWith(color: AtrioColors.guestTextPrimary),
    ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AtrioColors.guestSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AtrioColors.guestCardBorder),
        ),
        child: Row(children: [
          const Icon(Icons.people_outline_rounded, size: 22, color: AtrioColors.neonLimeDark),
          const SizedBox(width: 12),
          Expanded(child: Text(
            isPeople
                ? l.checkoutGuestsCountPeople(_guests)
                : l.checkoutGuestsCountSpaces(_guests),
            style: AtrioTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AtrioColors.guestTextPrimary),
          )),
          if (listing.capacity != null)
            Padding(padding: const EdgeInsets.only(right: 10), child: Text(l.checkoutMax(listing.capacity!), style: AtrioTypography.caption.copyWith(color: AtrioColors.guestTextTertiary))),
          _counterBtn(Icons.remove, _guests > 1 ? () { setState(() => _guests--); if (_pricingResult != null) _calcPricing(); } : null),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text('$_guests', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AtrioColors.guestTextPrimary))),
          _counterBtn(Icons.add, _guests < (listing.capacity ?? 10) ? () { setState(() => _guests++); if (_pricingResult != null) _calcPricing(); } : null),
        ]),
      ),
    ]);
  }

  Widget _buildCancellationPolicy(Listing listing) {
    final l = AppLocalizations.of(context);
    String policyTitle;
    String policyDesc;
    switch (listing.cancellationPolicy) {
      case 'strict':
        policyTitle = l.checkoutPolicyStrictTitle;
        policyDesc = l.checkoutPolicyStrictDesc;
        break;
      case 'moderate':
        policyTitle = l.checkoutPolicyModerateTitle;
        policyDesc = l.checkoutPolicyModerateDesc;
        break;
      default:
        policyTitle = l.checkoutPolicyFlexibleTitle;
        policyDesc = l.checkoutPolicyFlexibleDesc;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AtrioColors.ratingGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AtrioColors.ratingGold.withValues(alpha: 0.25)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.shield_outlined, size: 18, color: AtrioColors.ratingGold),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(policyTitle, style: AtrioTypography.labelMedium.copyWith(color: AtrioColors.guestTextPrimary)),
          const SizedBox(height: 3),
          Text(policyDesc, style: AtrioTypography.caption.copyWith(color: AtrioColors.guestTextSecondary, height: 1.4)),
        ])),
      ]),
    );
  }

  Widget _priceRow(String label, double amount) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: AtrioTypography.bodyMedium.copyWith(color: AtrioColors.guestTextSecondary)),
      Text(amount.toCLP, style: AtrioTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AtrioColors.guestTextPrimary)),
    ]),
  );

  Widget _counterBtn(IconData icon, VoidCallback? onTap) {
    final ok = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ok ? AtrioColors.neonLime.withValues(alpha: 0.25) : Colors.transparent,
          border: Border.all(color: ok ? AtrioColors.neonLimeDark.withValues(alpha: 0.4) : AtrioColors.guestCardBorder),
        ),
        child: Icon(icon, size: 16, color: ok ? AtrioColors.neonLimeDark : AtrioColors.guestTextTertiary),
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    final l = AppLocalizations.of(context);
    final isSandbox = MercadoPagoService.isSandbox;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AtrioColors.guestSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF009EE3).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // MP icon
              Container(
                width: 44, height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF009EE3).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.account_balance_wallet,
                    size: 22, color: Color(0xFF009EE3)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mercado Pago',
                        style: AtrioTypography.labelLarge
                            .copyWith(color: AtrioColors.guestTextPrimary)),
                    Text(
                      l.checkoutMpMethods,
                      style: AtrioTypography.caption
                          .copyWith(color: AtrioColors.guestTextSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.check_circle,
                  size: 20, color: Color(0xFF009EE3)),
            ],
          ),
          if (isSandbox) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.science_outlined,
                      size: 14, color: Colors.orange),
                  const SizedBox(width: 5),
                  Text(l.checkoutSandboxMode,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final icon in [
                Icons.credit_card,
                Icons.account_balance,
                Icons.qr_code_2,
                Icons.store,
              ]) ...[
                Icon(icon, size: 16, color: AtrioColors.guestTextTertiary),
                const SizedBox(width: 12),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
