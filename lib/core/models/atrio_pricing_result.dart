/// Canonical response from the `calculate_atrio_pricing` Postgres RPC.
///
/// This is the **single source of truth** for any price shown to the
/// user. The frontend never recalculates these values — it reads them
/// from the RPC and, on booking creation, persists the snapshot onto
/// the bookings row.
///
/// Mirrors the JSONB returned by the RPC. See
/// `supabase/migrations/029_servicio_atrio_pricing.sql`.
class AtrioPricingResult {
  /// Final precio_base for this booking (base_price * units). CLP.
  final int precioBase;

  /// 0.05 or 0.09 — the rate that drove the calc (before the minimum).
  final double porcentajeAtrio;

  /// Raw fee from `precio_base * porcentaje`. Pre-minimum.
  final int servicioAtrioCalculado;

  /// Actual fee charged. `max(calculado, minimo_clp)`.
  final int servicioAtrioAmount;

  /// True when the floor (`servicio_atrio_minimo_clp`) kicked in.
  final bool servicioAtrioMinimoAplicado;

  /// Configured minimum, mostly for display ("mínimo $1.490").
  final int servicioAtrioMinimoClp;

  /// What the customer pays. `precio_base + servicio_atrio_amount`.
  final int precioTotal;

  /// What the host should receive. Always equals `precio_base`.
  final int hostExpectedAmount;

  /// Count of host's paid+confirmed+non-refunded bookings BEFORE
  /// this one. Persisted on the booking row for audit/snapshot.
  final int hostPaidReservationCountAtBooking;

  /// True when this booking consumed one of the first 5 initial-benefit slots.
  final bool initialBenefitApplied;

  /// Whether the host's identity is verified — drives the rate decision.
  final bool hostVerified;

  /// Display label suggested by the server.
  /// "Servicio Atrio" or "Servicio Atrio inicial".
  final String serviceLabel;

  const AtrioPricingResult({
    required this.precioBase,
    required this.porcentajeAtrio,
    required this.servicioAtrioCalculado,
    required this.servicioAtrioAmount,
    required this.servicioAtrioMinimoAplicado,
    required this.servicioAtrioMinimoClp,
    required this.precioTotal,
    required this.hostExpectedAmount,
    required this.hostPaidReservationCountAtBooking,
    required this.initialBenefitApplied,
    required this.hostVerified,
    required this.serviceLabel,
  });

  factory AtrioPricingResult.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) =>
        v == null ? 0 : (v is int ? v : (v as num).toInt());
    double asDouble(dynamic v) =>
        v == null ? 0 : (v is double ? v : (v as num).toDouble());
    bool asBool(dynamic v) => v == true;

    return AtrioPricingResult(
      precioBase: asInt(json['precio_base']),
      porcentajeAtrio: asDouble(json['porcentaje_atrio']),
      servicioAtrioCalculado: asInt(json['servicio_atrio_calculado']),
      servicioAtrioAmount: asInt(json['servicio_atrio_amount']),
      servicioAtrioMinimoAplicado: asBool(json['servicio_atrio_minimo_aplicado']),
      servicioAtrioMinimoClp: asInt(json['servicio_atrio_minimo_clp']),
      precioTotal: asInt(json['precio_total']),
      hostExpectedAmount: asInt(json['host_expected_amount']),
      hostPaidReservationCountAtBooking:
          asInt(json['host_paid_reservation_count_at_booking']),
      initialBenefitApplied: asBool(json['initial_benefit_applied']),
      hostVerified: asBool(json['host_verified']),
      serviceLabel: (json['service_label'] as String?) ?? 'Servicio Atrio',
    );
  }

  /// Shape used when persisting onto the `bookings` row at creation.
  /// Keys match the column names added in migration 029.
  Map<String, dynamic> toBookingColumns() => {
        'precio_base': precioBase,
        'porcentaje_atrio': porcentajeAtrio,
        'servicio_atrio_calculado': servicioAtrioCalculado,
        'servicio_atrio_amount': servicioAtrioAmount,
        'servicio_atrio_minimo_aplicado': servicioAtrioMinimoAplicado,
        'precio_total': precioTotal,
        'host_expected_amount': hostExpectedAmount,
        'host_paid_reservation_count_at_booking':
            hostPaidReservationCountAtBooking,
        'initial_benefit_applied': initialBenefitApplied,
      };

  /// Pretty rate "5%" or "9%" for UI labels.
  String get porcentajeLabel =>
      '${(porcentajeAtrio * 100).toStringAsFixed(0)}%';
}
