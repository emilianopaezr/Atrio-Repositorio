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
import '../../../shared/widgets/availability_calendar.dart';
import '../../../shared/widgets/time_slot_picker.dart';

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
  int _paymentIdx = 0;
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
    if (dt == null) return 'Seleccionar';
    const m = ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${dt.day} ${m[dt.month]} ${dt.year}';
  }

  String _unitLabel(String u) {
    switch (u) {
      case 'night': return 'noche';
      case 'hour': return 'hora';
      case 'session': return 'sesión';
      case 'person': return 'persona';
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

  /// Calculate service fee with dynamic rate and $99 cap
  /// Uses 1% for promo hosts (< 5 bookings), 7% standard, capped at $99
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
    final mode = listing.rentalMode;

    if (mode == 'nights' && (_checkIn == null || _checkOut == null)) {
      _snack('Selecciona las fechas primero', isError: true);
      return;
    }
    if (mode == 'full_day' && _selectedDate == null) {
      _snack('Selecciona un día', isError: true);
      return;
    }
    if (mode == 'hours' && (_selectedDate == null || _selectedTimeSlots.isEmpty)) {
      _snack('Selecciona fecha y horarios', isError: true);
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
        if (mounted) _snack('Error en el cálculo. Recarga e intenta de nuevo.', isError: true);
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

      final result = await DatabaseService.createBookingWithCheck(bookingData);

      if (result == null) {
        if (mounted) _snack('Las fechas seleccionadas ya no están disponibles', isError: true);
        return;
      }

      if (mounted) {
        _snack('Reserva confirmada');
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) context.pushReplacement('/booking-confirmed');
      }
    } catch (e) {
      if (mounted) _snack('No se pudo completar la reserva. Intenta de nuevo.', isError: true);
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
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
    final listingAsync = ref.watch(listingDetailProvider(widget.listingId));

    return listingAsync.when(
      data: (data) {
        if (data == null) {
          return Scaffold(
            backgroundColor: AtrioColors.guestBackground,
            appBar: AppBar(backgroundColor: AtrioColors.guestBackground, elevation: 0),
            body: const Center(child: Text('No encontrado')),
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
        body: const Center(child: Text('Error al cargar')),
      ),
    );
  }

  Widget _page(Listing listing) {
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
        modeLabel = blockH > 1 ? 'Bloques de $blockH horas' : 'Reserva por horas';
        unitSuffix = '$totalH hora${totalH > 1 ? 's' : ''} ($blocks bloque${blocks > 1 ? 's' : ''})';
        break;
      case 'full_day':
        modeLabel = 'Día completo';
        unitSuffix = '1 día';
        break;
      default:
        modeLabel = 'Reserva por noches';
        unitSuffix = '$_nights noche${_nights > 1 ? 's' : ''}';
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
          'Confirmar Reserva',
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
                    Text('Fechas', style: AtrioTypography.headingSmall.copyWith(color: AtrioColors.guestTextPrimary)),
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
                    Text('Selecciona un día', style: AtrioTypography.headingSmall.copyWith(color: AtrioColors.guestTextPrimary)),
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
                    Text('Selecciona fecha', style: AtrioTypography.headingSmall.copyWith(color: AtrioColors.guestTextPrimary)),
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
                            'Selecciona 1 horario (precio por persona)',
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
                  Text('Resumen de Precio', style: AtrioTypography.headingSmall.copyWith(color: AtrioColors.guestTextPrimary)),
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
                              ? '\$${base.toStringAsFixed(0)} x $_guests persona${_guests > 1 ? 's' : ''}${mode == 'hours' ? ' x $blocks bloque${blocks > 1 ? 's' : ''}' : ''}'
                              : mode == 'hours'
                                  ? '\$${base.toStringAsFixed(0)} x $blocks bloque${blocks > 1 ? 's' : ''} (${blockH}h c/u)'
                                  : '\$${base.toStringAsFixed(0)} x $unitSuffix',
                          sub,
                        ),
                        if (clean > 0) _priceRow('Limpieza', clean),
                        _priceRow(
                          _isPromoRate
                              ? 'Tarifa promo ($feeLabel) 🎉'
                              : 'Tarifa de servicio ($feeLabel${fee >= 99 ? ', máx \$99' : ''})',
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
                                      'Tarifa promocional 1% — ${PricingEngineService.promoBookingThreshold - (_hostBookingsCount ?? 0)} reservas restantes',
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
                            Text('Total', style: AtrioTypography.headingSmall.copyWith(color: AtrioColors.guestTextPrimary)),
                            Text('\$${total.toStringAsFixed(2)}', style: AtrioTypography.priceLarge.copyWith(color: AtrioColors.guestTextPrimary)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ─── Payment method ───
                  Text('Método de Pago', style: AtrioTypography.headingSmall.copyWith(color: AtrioColors.guestTextPrimary)),
                  const SizedBox(height: 12),
                  _paymentTile(0, Icons.credit_card_rounded, 'Visa **** 4242', 'Exp 12/24'),
                  const SizedBox(height: 8),
                  _paymentTile(1, Icons.apple, 'Apple Pay', null),

                  const SizedBox(height: 24),

                  // ─── Cancellation policy ───
                  _buildCancellationPolicy(listing),

                  const SizedBox(height: 16),

                  // ─── Security ───
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline, size: 13, color: AtrioColors.guestTextTertiary),
                      const SizedBox(width: 6),
                      Text(
                        'PAGO SEGURO CIFRADO CON SSL',
                        style: GoogleFonts.inter(fontSize: 10, color: AtrioColors.guestTextTertiary, letterSpacing: 1, fontWeight: FontWeight.w600),
                      ),
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
                          Text(
                            listing.instantBooking ? 'Reservar Ahora' : 'Confirmar y Reservar',
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\$${total.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black.withValues(alpha: 0.7)),
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
                  Text('\$${base.toStringAsFixed(0)}', style: AtrioTypography.priceMedium.copyWith(color: AtrioColors.guestTextPrimary)),
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
    return Row(children: [
      CircleAvatar(
        radius: 22,
        backgroundColor: AtrioColors.neonLime.withValues(alpha: 0.2),
        backgroundImage: host['photo_url'] != null ? NetworkImage(host['photo_url'] as String) : null,
        child: host['photo_url'] == null ? const Icon(Icons.person, size: 22, color: AtrioColors.neonLimeDark) : null,
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(host['display_name'] as String? ?? 'Anfitrión', style: AtrioTypography.labelMedium.copyWith(color: AtrioColors.guestTextPrimary)),
          if (host['is_verified'] == true) ...[const SizedBox(width: 5), const Icon(Icons.verified, size: 16, color: AtrioColors.neonLimeDark)],
        ]),
        Text('Anfitrión', style: AtrioTypography.caption.copyWith(color: AtrioColors.guestTextTertiary)),
      ])),
    ]);
  }

  Widget _buildDateSummary(Listing listing) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AtrioColors.guestSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AtrioColors.neonLimeDark.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Check-in', style: AtrioTypography.caption.copyWith(color: AtrioColors.guestTextTertiary)),
          const SizedBox(height: 4),
          Text(_fmt(_checkIn), style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
        ])),
        Container(width: 1, height: 36, color: AtrioColors.guestCardBorder),
        Expanded(child: Padding(padding: const EdgeInsets.only(left: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Check-out', style: AtrioTypography.caption.copyWith(color: AtrioColors.guestTextTertiary)),
          const SizedBox(height: 4),
          Text(_fmt(_checkOut), style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
        ]))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: AtrioColors.neonLime, borderRadius: BorderRadius.circular(10)),
          child: Text('$_nights noche${_nights > 1 ? 's' : ''}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black)),
        ),
      ]),
    );
  }

  Widget _buildGuestsSection(Listing listing) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
      listing.type == 'experience' || listing.type == 'service' ? 'Personas' : 'Huéspedes',
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
            listing.type == 'experience' || listing.type == 'service'
                ? '$_guests persona${_guests > 1 ? 's' : ''}'
                : '$_guests ${_guests == 1 ? 'huésped' : 'huéspedes'}',
            style: AtrioTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AtrioColors.guestTextPrimary),
          )),
          if (listing.capacity != null)
            Padding(padding: const EdgeInsets.only(right: 10), child: Text('máx ${listing.capacity}', style: AtrioTypography.caption.copyWith(color: AtrioColors.guestTextTertiary))),
          _counterBtn(Icons.remove, _guests > 1 ? () { setState(() => _guests--); if (_pricingResult != null) _calcPricing(); } : null),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text('$_guests', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AtrioColors.guestTextPrimary))),
          _counterBtn(Icons.add, _guests < (listing.capacity ?? 10) ? () { setState(() => _guests++); if (_pricingResult != null) _calcPricing(); } : null),
        ]),
      ),
    ]);
  }

  Widget _buildCancellationPolicy(Listing listing) {
    String policyTitle;
    String policyDesc;
    switch (listing.cancellationPolicy) {
      case 'strict':
        policyTitle = 'Cancelación estricta';
        policyDesc = 'Reembolso del 50% hasta 7 días antes. Sin reembolso después.';
        break;
      case 'moderate':
        policyTitle = 'Cancelación moderada';
        policyDesc = 'Cancelación gratuita hasta 5 días antes. Después se cobra el 50%.';
        break;
      default:
        policyTitle = 'Cancelación flexible';
        policyDesc = 'Cancelación gratuita hasta 24 horas antes del check-in. Después se cobra el 50%.';
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
      Text('\$${amount.toStringAsFixed(2)}', style: AtrioTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AtrioColors.guestTextPrimary)),
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

  Widget _paymentTile(int idx, IconData icon, String title, String? sub) {
    final sel = _paymentIdx == idx;
    return GestureDetector(
      onTap: () => setState(() => _paymentIdx = idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: sel ? AtrioColors.neonLime.withValues(alpha: 0.1) : AtrioColors.guestSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: sel ? AtrioColors.neonLimeDark : AtrioColors.guestCardBorder, width: sel ? 1.5 : 1),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 28,
            decoration: BoxDecoration(color: sel ? AtrioColors.neonLimeDark.withValues(alpha: 0.15) : AtrioColors.guestSurfaceVariant, borderRadius: BorderRadius.circular(6)),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: sel ? AtrioColors.neonLimeDark : AtrioColors.guestTextSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AtrioTypography.labelMedium.copyWith(color: AtrioColors.guestTextPrimary)),
            if (sub != null) Text(sub, style: AtrioTypography.caption.copyWith(color: AtrioColors.guestTextTertiary)),
          ])),
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: sel ? AtrioColors.neonLimeDark : AtrioColors.guestCardBorder, width: sel ? 2 : 1.5)),
            child: sel ? Center(child: Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: AtrioColors.neonLimeDark))) : null,
          ),
        ]),
      ),
    );
  }
}
