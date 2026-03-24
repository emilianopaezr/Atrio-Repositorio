/// Represents the result of a pricing calculation from the server.
/// Not using Freezed here to avoid build_runner dependency for new models —
/// keeps deployment simple and these are read-only DTOs.
class PricingResult {
  final String pricingModel;
  final String? pricingPhase;
  final int nights;
  final double baseTotal;
  final double cleaningFee;
  final double hostCommissionRate;
  final double guestServiceFeeRate;
  final double hostCommissionAmount;
  final double guestServiceFeeAmount;
  final double platformRevenue;
  final double hostPayoutAmount;
  final double total;
  final double? basePrice;
  final String? priceUnit;
  final int? guestsCount;

  const PricingResult({
    required this.pricingModel,
    this.pricingPhase,
    required this.nights,
    required this.baseTotal,
    this.cleaningFee = 0,
    required this.hostCommissionRate,
    required this.guestServiceFeeRate,
    required this.hostCommissionAmount,
    required this.guestServiceFeeAmount,
    required this.platformRevenue,
    required this.hostPayoutAmount,
    required this.total,
    this.basePrice,
    this.priceUnit,
    this.guestsCount,
  });

  factory PricingResult.fromJson(Map<String, dynamic> json) {
    return PricingResult(
      pricingModel: json['pricing_model'] as String? ?? 'UNKNOWN',
      pricingPhase: json['pricing_phase'] as String?,
      nights: (json['nights'] as num?)?.toInt() ?? 1,
      baseTotal: (json['base_total'] as num?)?.toDouble() ?? 0,
      cleaningFee: (json['cleaning_fee'] as num?)?.toDouble() ?? 0,
      hostCommissionRate: (json['host_commission_rate'] as num?)?.toDouble() ?? 0,
      guestServiceFeeRate: (json['guest_service_fee_rate'] as num?)?.toDouble() ?? 0,
      hostCommissionAmount: (json['host_commission_amount'] as num?)?.toDouble() ?? 0,
      guestServiceFeeAmount: (json['guest_service_fee_amount'] as num?)?.toDouble() ?? 0,
      platformRevenue: (json['platform_revenue'] as num?)?.toDouble() ?? 0,
      hostPayoutAmount: (json['host_payout_amount'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      basePrice: (json['base_price'] as num?)?.toDouble(),
      priceUnit: json['price_unit'] as String?,
      guestsCount: (json['guests_count'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'pricing_model': pricingModel,
        'pricing_phase': pricingPhase,
        'nights': nights,
        'base_total': baseTotal,
        'cleaning_fee': cleaningFee,
        'host_commission_rate': hostCommissionRate,
        'guest_service_fee_rate': guestServiceFeeRate,
        'host_commission_amount': hostCommissionAmount,
        'guest_service_fee_amount': guestServiceFeeAmount,
        'platform_revenue': platformRevenue,
        'host_payout_amount': hostPayoutAmount,
        'total': total,
      };

  /// User-friendly label for the pricing model
  String get modelLabel {
    switch (pricingModel) {
      case 'PROMO_1_PERCENT':
        return 'Promo 1% (primeras 5 reservas)';
      case 'HOOK_1_PERCENT':
        return 'Gancho 1%';
      case 'STANDARD_7_CAP99':
        return 'Comisión 7% (máx \$99)';
      case 'FLAT_FEE_CAP':
        return 'Comisión con Tope';
      case 'EARLY_ADOPTER':
        return 'Early Adopter';
      default:
        return pricingModel;
    }
  }

  /// User-friendly label for the pricing phase
  String? get phaseLabel {
    switch (pricingPhase) {
      case 'WELCOME':
        return 'Bienvenida — 0% comisión';
      case 'STANDARD':
        return 'Estándar';
      case 'ELITE':
        return 'Elite — comisión reducida';
      default:
        return pricingPhase;
    }
  }

  /// Description for the guest showing what model applies
  String get guestDescription {
    switch (pricingModel) {
      case 'PROMO_1_PERCENT':
        return 'Tarifa promocional 1% (primeras 5 reservas del host)';
      case 'HOOK_1_PERCENT':
        return 'Tarifa especial de lanzamiento';
      case 'STANDARD_7_CAP99':
        return 'Tarifa estándar (7%, máx \$99)';
      case 'FLAT_FEE_CAP':
        return 'Tarifa protegida con tope máximo';
      case 'EARLY_ADOPTER':
        if (pricingPhase == 'WELCOME') return 'Tarifa de bienvenida';
        if (pricingPhase == 'ELITE') return 'Tarifa Elite';
        return 'Tarifa estándar';
      default:
        return '';
    }
  }

  bool get hasCommissionCap => guestServiceFeeAmount >= 99;

  /// Whether the fee was capped at $99
  bool get isFeeCapped {
    final raw = (baseTotal + cleaningFee) * guestServiceFeeRate;
    return raw > 99 && guestServiceFeeAmount <= 99;
  }
}
