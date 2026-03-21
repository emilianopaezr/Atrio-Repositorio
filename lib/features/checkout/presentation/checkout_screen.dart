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

class CheckoutScreen extends ConsumerStatefulWidget {
  final String listingId;
  const CheckoutScreen({super.key, required this.listingId});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  static const _testMode = true;

  DateTime? _checkIn;
  DateTime? _checkOut;
  int _guests = 1;
  bool _isBooking = false;
  PricingResult? _pricingResult;
  int _paymentIdx = 0;

  int get _nights {
    if (_checkIn == null || _checkOut == null) return 1;
    return _checkOut!.difference(_checkIn!).inDays.clamp(1, 365);
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

  Future<void> _pickDates() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _checkIn != null && _checkOut != null
          ? DateTimeRange(start: _checkIn!, end: _checkOut!)
          : null,
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: AtrioColors.neonLimeDark,
            onPrimary: Colors.black,
            surface: Colors.white,
            onSurface: AtrioColors.guestTextPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      setState(() {
        _checkIn = range.start;
        _checkOut = range.end;
        _pricingResult = null;
      });
      _calcPricing();
    }
  }

  Future<void> _calcPricing() async {
    final data = ref.read(listingDetailProvider(widget.listingId)).value;
    if (data == null || _checkIn == null || _checkOut == null) return;
    final listing = Listing.fromJson(data);
    final uid = AuthService.currentUser?.id;
    if (uid == null) return;

    try {
      final r = await PricingEngineService.calculatePricing(
        listingId: listing.id, guestId: uid, hostId: listing.hostId,
        checkIn: _checkIn!, checkOut: _checkOut!, guestsCount: _guests,
      );
      if (mounted) setState(() => _pricingResult = r);
    } catch (_) {
      final p = PricingEngineService.previewPricing(
        basePrice: listing.basePrice ?? 0,
        cleaningFee: listing.cleaningFee,
        nights: _nights,
      );
      if (mounted) setState(() => _pricingResult = p);
    }
  }

  Future<void> _confirm(Listing listing) async {
    if (_checkIn == null || _checkOut == null) {
      _snack('Selecciona las fechas primero', isError: true);
      return;
    }
    setState(() => _isBooking = true);
    try {
      final pricing = _pricingResult ?? await PricingEngineService.calculatePricing(
        listingId: listing.id, guestId: AuthService.currentUser!.id,
        hostId: listing.hostId, checkIn: _checkIn!, checkOut: _checkOut!,
        guestsCount: _guests,
      );
      if (_testMode) await Future.delayed(const Duration(milliseconds: 1500));

      await DatabaseService.createBooking({
        'listing_id': listing.id,
        'host_id': listing.hostId,
        'guest_id': AuthService.currentUser!.id,
        'check_in': _checkIn!.toIso8601String(),
        'check_out': _checkOut!.toIso8601String(),
        'guests_count': _guests,
        'base_total': pricing.baseTotal,
        'cleaning_fee': pricing.cleaningFee,
        'service_fee': pricing.guestServiceFeeAmount,
        'total': pricing.total,
        'status': 'pending',
        'payment_status': 'pending',
      });

      if (mounted) {
        _snack('Reserva confirmada');
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) context.pushReplacement('/booking-confirmed');
      }
    } catch (_) {
      if (mounted) _snack('No se pudo completar la reserva. Intenta de nuevo.', isError: true);
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.roboto(
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
    final base = listing.basePrice ?? 0;
    final p = _pricingResult;
    final sub = p?.baseTotal ?? base * _nights;
    final clean = p?.cleaningFee ?? listing.cleaningFee;
    final fee = p?.guestServiceFeeAmount ?? sub * 0.07;
    final total = p?.total ?? sub + clean + fee;
    final feeLabel = p != null ? '${(p.guestServiceFeeRate * 100).toStringAsFixed(0)}%' : '7%';
    final host = listing.hostData;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

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
                  Container(
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
                                ? CachedNetworkImage(
                                    imageUrl: listing.images.first,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: AtrioColors.guestSurfaceVariant,
                                    child: const Icon(Icons.image, color: AtrioColors.guestTextTertiary),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                listing.title,
                                style: AtrioTypography.labelLarge.copyWith(color: AtrioColors.guestTextPrimary),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              if (listing.city != null)
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 13, color: AtrioColors.guestTextTertiary),
                                    const SizedBox(width: 3),
                                    Text(listing.city!, style: AtrioTypography.caption.copyWith(color: AtrioColors.guestTextSecondary)),
                                  ],
                                ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    '\$${base.toStringAsFixed(0)}',
                                    style: AtrioTypography.priceMedium.copyWith(color: AtrioColors.guestTextPrimary),
                                  ),
                                  Text(
                                    ' / ${_unitLabel(listing.priceUnit)}',
                                    style: AtrioTypography.caption.copyWith(color: AtrioColors.guestTextSecondary),
                                  ),
                                  const Spacer(),
                                  if (listing.rating > 0) ...[
                                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB800)),
                                    const SizedBox(width: 3),
                                    Text(
                                      listing.rating.toStringAsFixed(1),
                                      style: AtrioTypography.caption.copyWith(fontWeight: FontWeight.w600, color: AtrioColors.guestTextPrimary),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ─── Host info ───
                  if (host != null) ...[
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AtrioColors.neonLime.withValues(alpha: 0.2),
                          backgroundImage: host['photo_url'] != null
                              ? NetworkImage(host['photo_url'] as String)
                              : null,
                          child: host['photo_url'] == null
                              ? const Icon(Icons.person, size: 22, color: AtrioColors.neonLimeDark)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    host['display_name'] as String? ?? 'Anfitrión',
                                    style: AtrioTypography.labelMedium.copyWith(color: AtrioColors.guestTextPrimary),
                                  ),
                                  if (host['is_verified'] == true) ...[
                                    const SizedBox(width: 5),
                                    const Icon(Icons.verified, size: 16, color: AtrioColors.neonLimeDark),
                                  ],
                                ],
                              ),
                              Text('Anfitrión', style: AtrioTypography.caption.copyWith(color: AtrioColors.guestTextTertiary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1, color: AtrioColors.guestCardBorder),
                    const SizedBox(height: 20),
                  ],

                  // ─── Dates section ───
                  Text('Fechas', style: AtrioTypography.headingSmall.copyWith(color: AtrioColors.guestTextPrimary)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickDates,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AtrioColors.guestSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _checkIn != null
                              ? AtrioColors.neonLimeDark.withValues(alpha: 0.5)
                              : AtrioColors.guestCardBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Entrada', style: AtrioTypography.caption.copyWith(color: AtrioColors.guestTextTertiary)),
                                const SizedBox(height: 4),
                                Text(
                                  _fmt(_checkIn),
                                  style: GoogleFonts.roboto(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _checkIn != null ? AtrioColors.guestTextPrimary : AtrioColors.neonLimeDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1, height: 36,
                            color: AtrioColors.guestCardBorder,
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Salida', style: AtrioTypography.caption.copyWith(color: AtrioColors.guestTextTertiary)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _fmt(_checkOut),
                                    style: GoogleFonts.roboto(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: _checkOut != null ? AtrioColors.guestTextPrimary : AtrioColors.neonLimeDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_checkIn != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AtrioColors.neonLime,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$_nights ${_unitLabel(listing.priceUnit)}${_nights > 1 ? 's' : ''}',
                                style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black),
                              ),
                            )
                          else
                            const Icon(Icons.edit_calendar_outlined, size: 20, color: AtrioColors.neonLimeDark),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ─── Guests section ───
                  Text('Huéspedes', style: AtrioTypography.headingSmall.copyWith(color: AtrioColors.guestTextPrimary)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AtrioColors.guestSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AtrioColors.guestCardBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.people_outline_rounded, size: 22, color: AtrioColors.neonLimeDark),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '$_guests ${_guests == 1 ? 'huésped' : 'huéspedes'}',
                            style: AtrioTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AtrioColors.guestTextPrimary,
                            ),
                          ),
                        ),
                        if (listing.capacity != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Text(
                              'máx ${listing.capacity}',
                              style: AtrioTypography.caption.copyWith(color: AtrioColors.guestTextTertiary),
                            ),
                          ),
                        _counterBtn(Icons.remove, _guests > 1 ? () {
                          setState(() => _guests--);
                          if (_pricingResult != null) _calcPricing();
                        } : null),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text('$_guests', style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.w800, color: AtrioColors.guestTextPrimary)),
                        ),
                        _counterBtn(Icons.add, _guests < (listing.capacity ?? 10) ? () {
                          setState(() => _guests++);
                          if (_pricingResult != null) _calcPricing();
                        } : null),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ─── Pricing badge ───
                  if (p != null && p.guestDescription.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AtrioColors.neonLime.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AtrioColors.neonLimeDark.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, size: 16, color: AtrioColors.neonLimeDark),
                          const SizedBox(width: 8),
                          Expanded(child: Text(
                            p.guestDescription,
                            style: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w600, color: AtrioColors.neonLimeDark),
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

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
                        _priceRow('\$${base.toStringAsFixed(0)} x $_nights ${_unitLabel(listing.priceUnit)}${_nights > 1 ? 's' : ''}', sub),
                        if (clean > 0) _priceRow('Limpieza', clean),
                        _priceRow('Tarifa de servicio ($feeLabel)', fee),
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
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFB800).withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.shield_outlined, size: 18, color: Color(0xFFFFB800)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Cancelación flexible', style: AtrioTypography.labelMedium.copyWith(color: AtrioColors.guestTextPrimary)),
                              const SizedBox(height: 3),
                              Text(
                                'Cancelación gratuita hasta 24 horas antes del check-in. Después se cobra el 50%.',
                                style: AtrioTypography.caption.copyWith(color: AtrioColors.guestTextSecondary, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ─── Security ───
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline, size: 13, color: AtrioColors.guestTextTertiary),
                      const SizedBox(width: 6),
                      Text(
                        'PAGO SEGURO CIFRADO CON SSL',
                        style: GoogleFonts.roboto(fontSize: 10, color: AtrioColors.guestTextTertiary, letterSpacing: 1, fontWeight: FontWeight.w600),
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
                            'Confirmar y Reservar',
                            style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\$${total.toStringAsFixed(2)}',
                            style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black.withValues(alpha: 0.7)),
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

  // ─── Helpers ───

  Widget _priceRow(String label, double amount) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AtrioTypography.bodyMedium.copyWith(color: AtrioColors.guestTextSecondary)),
        Text('\$${amount.toStringAsFixed(2)}', style: AtrioTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AtrioColors.guestTextPrimary)),
      ],
    ),
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
        child: Row(
          children: [
            Container(
              width: 40, height: 28,
              decoration: BoxDecoration(
                color: sel ? AtrioColors.neonLimeDark.withValues(alpha: 0.15) : AtrioColors.guestSurfaceVariant,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: sel ? AtrioColors.neonLimeDark : AtrioColors.guestTextSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AtrioTypography.labelMedium.copyWith(color: AtrioColors.guestTextPrimary)),
                  if (sub != null) Text(sub, style: AtrioTypography.caption.copyWith(color: AtrioColors.guestTextTertiary)),
                ],
              ),
            ),
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: sel ? AtrioColors.neonLimeDark : AtrioColors.guestCardBorder, width: sel ? 2 : 1.5),
              ),
              child: sel ? Center(child: Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: AtrioColors.neonLimeDark))) : null,
            ),
          ],
        ),
      ),
    );
  }
}
