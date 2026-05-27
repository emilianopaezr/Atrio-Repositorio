import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../core/models/atrio_pricing_result.dart';
import '../../../core/models/listing_model.dart';
import '../../../core/models/pricing_result_model.dart';
import '../../../core/providers/listings_provider.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/pricing_engine_service.dart';
import '../../../core/services/mercadopago_service.dart';
import '../../../shared/widgets/availability_calendar.dart';
import '../../../shared/widgets/price_breakdown_card.dart';
import '../../../shared/widgets/time_slot_picker.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/error_handler.dart';
import '../../../l10n/app_localizations.dart';
import 'card_payment_screen.dart';

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
  // Server-side Servicio Atrio breakdown — refreshed every time
  // dates/guests/slots change. Source of truth for fee + total.
  AtrioPricingResult? _atrioPricing;
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

    // Mirror through the new server-side engine so the displayed fee +
    // total come from the canonical RPC. Done after the legacy
    // calculation so the UI shows something immediately, then refines.
    unawaited(_refreshAtrioPricing(l));
  }

  /// Calls calculate_atrio_pricing for the current selection and stores
  /// the result. The "effective base" pre-multiplies nights / blocks /
  /// guests on the client, and the RPC then derives the rate + minimum.
  Future<void> _refreshAtrioPricing(Listing l) async {
    final mode = l.rentalMode;
    final basePrice = (l.basePrice ?? 0).toInt();
    final perPerson = _isPerPerson(l);
    final guestMultiplier = perPerson ? _guests : 1;
    int units;
    if (mode == 'hours') {
      units = _blockCount(l) > 0 ? _blockCount(l) : 1;
    } else if (mode == 'full_day') {
      units = 1;
    } else {
      if (_checkIn == null || _checkOut == null) return;
      units = _nights;
    }
    final effectiveUnits = units * guestMultiplier;
    if (basePrice <= 0 || effectiveUnits <= 0) return;
    try {
      final p = await PricingEngineService.calculateAtrioPricing(
        hostId: l.hostId,
        basePrice: basePrice,
        units: effectiveUnits,
      );
      if (mounted) setState(() => _atrioPricing = p);
    } catch (_) {
      // Network failure: leave previous snapshot in place and let the
      // legacy preview render. The confirm step has its own guard.
    }
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
        cleaningFee: clean,
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

      // Source of truth for the Servicio Atrio fee + total comes from
      // the most recent RPC response. Re-fetch right before submitting
      // so the persisted snapshot matches the server (and any host
      // verification / count changes since the user opened the screen).
      final atrioPricing =
          await PricingEngineService.calculateAtrioPricing(
        hostId: listing.hostId,
        basePrice: (listing.basePrice ?? 0).toInt(),
        units: units * (_isPerPerson(listing) ? _guests : 1),
      );

      // The customer must pay base + cleaning + Servicio Atrio.
      // Cleaning is treated as a pass-through to the host (RPC ignores it).
      final effectiveTotal =
          atrioPricing.precioBase + clean.round() + atrioPricing.servicioAtrioAmount;

      final bookingData = {
        'listing_id': listing.id,
        'host_id': listing.hostId,
        'guest_id': AuthService.currentUser!.id,
        'check_in': effectiveCheckIn.toIso8601String(),
        'check_out': effectiveCheckOut.toIso8601String(),
        'guests_count': _guests,
        // Legacy columns (kept for backward compat during the migration)
        'base_total': atrioPricing.precioBase.toDouble(),
        'cleaning_fee': clean,
        'service_fee': atrioPricing.servicioAtrioAmount.toDouble(),
        'total': effectiveTotal.toDouble(),
        // Servicio Atrio snapshot (new canonical columns)
        ...atrioPricing.toBookingColumns(),
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

  /// Process payment via the in-app Card form (Checkout API server-side).
  ///
  /// 1. Pushes [CardPaymentScreen] which collects card data + RUT.
  /// 2. The screen calls the Edge Function `mp-create-payment` which
  ///    tokenizes server-side with the access token (avoids public_key
  ///    live_mode mismatch), pays, and returns the result.
  /// 3. Handles the [PaymentResult] returned via Navigator.pop.
  Future<void> _processPayment({
    required Listing listing,
    required String bookingId,
    required double total,
    required double serviceFee,
  }) async {
    AnalyticsService.logBeginCheckout(
      listingId: listing.id,
      amount: total,
      currency: 'CLP',
    );
    try {
      final paymentResult = await Navigator.of(context).push<PaymentResult>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => CardPaymentScreen(
            bookingId: bookingId,
            total: total,
            listingTitle: listing.title,
          ),
        ),
      );

      if (!mounted) return;

      if (paymentResult == null) {
        // User closed the form without submitting.
        _snack(
          AppLocalizations.of(context).checkoutPaymentPending,
          isError: false,
        );
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
    // Verify against the DB (kept fresh by the mp-webhook edge function).
    // We re-read after a short delay so the webhook has time to land —
    // typically MP fires within 1–2s of redirect.
    if (paymentId != null && paymentId.isNotEmpty) {
      try {
        await Future.delayed(const Duration(seconds: 2));
        final status =
            await MercadoPagoService.getBookingPaymentStatus(bookingId);
        if (status != null && !status.isApproved) {
          if (status.isPending) {
            await _handlePaymentPending(bookingId, paymentId);
            return;
          }
          if (mounted) {
            _snack(
              AppLocalizations.of(context)
                  .checkoutPaymentNotApproved(status.status),
              isError: true,
            );
          }
          return;
        }
      } catch (_) {
        // Best-effort. Trust the previous result if DB lookup fails.
      }
    }

    // The Edge Function `mp-create-payment` already updated payment_status
    // server-side, and the DB trigger `trg_booking_payment_paid` already
    // inserted the host earning + platform fee transactions and bumped
    // host_profiles.pending_balance. Doing it again from the client fails
    // with "permission denied" (RLS denies guest writes to transactions
    // and host_profiles), which surfaces as the red snackbar.
    //
    // Nothing to do here besides UX feedback.
    AnalyticsService.logPurchase(
      bookingId: bookingId,
      amount: total,
      currency: 'CLP',
    );
    if (mounted) {
      _snack(AppLocalizations.of(context).checkoutPaymentApproved);
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) context.pushReplacement('/booking-confirmed');
    }
  }

  /// Payment pending → redirect to bookings. Edge Function already updated
  /// the booking server-side.
  Future<void> _handlePaymentPending(
      String bookingId, String? paymentId) async {
    if (mounted) {
      _snack(AppLocalizations.of(context).checkoutPaymentInProcess);
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) context.go('/guest/bookings');
    }
  }

  /// Payment rejected → show error, allow retry. Edge Function already set
  /// payment_status='failed' server-side.
  Future<void> _handlePaymentRejected(
      String bookingId, PaymentResult result) async {

    if (mounted) {
      final l = AppLocalizations.of(context);
      // Try to get specific rejection reason
      String errorMsg = l.checkoutPaymentRejected;
      // Detailed rejection reason can be inspected later via MP dashboard;
      // we keep a generic localized message here to avoid exposing the
      // access token from the client.

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
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: AtrioColors.guestBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Editorial eyebrow + lime accent bar
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AtrioColors.error,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'PAGO RECHAZADO',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AtrioColors.error,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                l.checkoutRejectedTitle,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AtrioColors.guestTextPrimary,
                  letterSpacing: -0.6,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l.checkoutRejectedDesc,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: AtrioColors.guestTextSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              // Primary: retry (lime CTA)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.black),
                  label: Text(
                    l.checkoutRetryBtn,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      letterSpacing: -0.2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AtrioColors.neonLime,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Secondary: go to bookings (ghost)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.go('/guest/bookings');
                  },
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: AtrioColors.guestCardBorder),
                    ),
                  ),
                  child: Text(
                    l.checkoutGoToBookings,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AtrioColors.guestTextPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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

    // Subtotal + cleaning still come from the helpers (they encode the
    // multi-mode pricing). The Atrio fee + total are driven by the
    // server-side snapshot when present, falling back to the legacy
    // calc while the RPC is loading or after a network failure.
    final sub = _calcSubtotal(listing);
    final clean = mode == 'hours' ? 0.0 : listing.cleaningFee;
    final atrio = _atrioPricing;
    final fee = atrio != null
        ? atrio.servicioAtrioAmount.toDouble()
        : _calcServiceFee(sub, clean);
    final total = atrio != null
        ? (atrio.precioBase + clean.round() + atrio.servicioAtrioAmount).toDouble()
        : (sub + clean + fee);
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
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Editorial header ───
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: AtrioColors.guestTextPrimary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 32, minHeight: 32),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.checkoutEyebrow,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AtrioColors.guestTextTertiary,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l.checkoutTitle,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AtrioColors.guestTextPrimary,
                        letterSpacing: -0.8,
                        height: 1.05,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Listing card ───
                  _buildListingCard(listing, base),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        mode == 'hours'
                            ? Icons.access_time_rounded
                            : mode == 'full_day'
                                ? Icons.today_rounded
                                : Icons.nightlight_round,
                        size: 14,
                        color: AtrioColors.guestTextSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        modeLabel,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AtrioColors.guestTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _hairline(),
                  const SizedBox(height: 22),

                  // ─── Date/Time selection (mode-specific) ───
                  if (mode == 'nights') ...[
                    _sectionTitle(l.checkoutDatesLabel),
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
                    _sectionTitle(l.checkoutSelectDayLabel),
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
                    _sectionTitle(l.checkoutSelectDateLabel),
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

                  const SizedBox(height: 22),
                  _hairline(),
                  const SizedBox(height: 22),

                  // ─── Guests section ───
                  _buildGuestsSection(listing),
                  const SizedBox(height: 22),
                  _hairline(),
                  const SizedBox(height: 22),

                  // ─── Total + desglose colapsable (estilo Airbnb) ───
                  _sectionTitle(l.checkoutPriceSummary),
                  const SizedBox(height: 14),
                  PriceBreakdownCard(
                    // Caption uses the all-inclusive per-unit price so the
                    // guest never sees the without-fee number outside the
                    // breakdown sheet.
                    caption: _isPerPerson(listing)
                        ? (mode == 'hours'
                            ? l.checkoutPriceBasePersonHours(base.toCLPWithFee, _guests, blocks)
                            : l.checkoutPriceBasePerson(base.toCLPWithFee, _guests))
                        : mode == 'hours'
                            ? l.checkoutPriceBaseHoursSimple(base.toCLPWithFee, blocks, blockH)
                            : l.checkoutPriceBaseUnit(base.toCLPWithFee, unitSuffix),
                    totalLabel: l.bookingTotal,
                    total: total,
                    // Inside the breakdown sheet we show the real math:
                    // host's subtotal, optional cleaning, Atrio fee, total.
                    items: [
                      PriceBreakdownItem(l.qsServicePrice, sub),
                      if (clean > 0) PriceBreakdownItem(l.checkoutCleaning, clean),
                      PriceBreakdownItem(
                        _atrioPricing == null
                            // Loading state — show neutral label.
                            ? l.qsAtrioFee
                            : (_atrioPricing!.servicioAtrioMinimoAplicado
                                ? l.qsAtrioFeeMinApplied
                                : (_atrioPricing!.initialBenefitApplied
                                    ? '${l.qsAtrioFeeInitial} (${_atrioPricing!.porcentajeLabel})'
                                    : '${l.qsAtrioFee} (${_atrioPricing!.porcentajeLabel})')),
                        fee,
                      ),
                    ],
                    footer: (_atrioPricing?.initialBenefitApplied ?? false)
                        ? Container(
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
                                    l.qsAtrioBenefitNote,
                                    style: GoogleFonts.inter(fontSize: 11, color: AtrioColors.neonLimeDark, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : null,
                  ),

                  const SizedBox(height: 22),
                  _hairline(),
                  const SizedBox(height: 22),

                  // ─── Payment method (Mercado Pago) ───
                  _sectionTitle(l.checkoutPaymentMethodTitle),
                  const SizedBox(height: 12),
                  _buildPaymentMethodCard(),

                  const SizedBox(height: 22),
                  _hairline(),
                  const SizedBox(height: 22),

                  // ─── Cancellation policy ───
                  _buildCancellationPolicy(listing),

                  const SizedBox(height: 22),

                  // ─── Security badge ───
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline_rounded,
                            size: 12,
                            color: AtrioColors.guestTextTertiary),
                        const SizedBox(width: 5),
                        Text(
                          l.checkoutPaySecureBadge,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AtrioColors.guestTextTertiary,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ─── Bottom bar (minimal, white) ───
          Container(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + bottomPadding),
            decoration: const BoxDecoration(
              color: AtrioColors.guestSurface,
              border: Border(
                top: BorderSide(
                    color: AtrioColors.guestCardBorder, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        total.toCLP,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AtrioColors.guestTextPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Total',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AtrioColors.guestTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isBooking ? null : () => _confirm(listing),
                    borderRadius: BorderRadius.circular(14),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 26, vertical: 14),
                      decoration: BoxDecoration(
                        color: _isBooking
                            ? AtrioColors.guestTextPrimary.withValues(alpha: 0.5)
                            : AtrioColors.guestTextPrimary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: _isBooking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Pagar',
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  // ─── Sub-widgets ───

  Widget _hairline() => Container(
        height: 1,
        color: AtrioColors.guestCardBorder,
      );

  Widget _sectionTitle(String text) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: AtrioColors.guestTextPrimary,
          letterSpacing: -0.4,
        ),
      );

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
                  // All-inclusive (base + 7% fee).
                  Text(base.toCLPWithFee, style: AtrioTypography.priceMedium.copyWith(color: AtrioColors.guestTextPrimary)),
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
