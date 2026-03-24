enum AppMode { guest, host }

enum RentalMode {
  hours,
  fullDay,
  nights;

  String get dbValue {
    switch (this) {
      case RentalMode.hours:
        return 'hours';
      case RentalMode.fullDay:
        return 'full_day';
      case RentalMode.nights:
        return 'nights';
    }
  }

  String get label {
    switch (this) {
      case RentalMode.hours:
        return 'Por horas';
      case RentalMode.fullDay:
        return 'Día completo';
      case RentalMode.nights:
        return 'Por noches';
    }
  }

  String get description {
    switch (this) {
      case RentalMode.hours:
        return 'Las personas reservan bloques horarios';
      case RentalMode.fullDay:
        return 'Reserva de un día completo';
      case RentalMode.nights:
        return 'Check-in / Check-out por noches';
    }
  }

  String get emoji {
    switch (this) {
      case RentalMode.hours:
        return '⏱️';
      case RentalMode.fullDay:
        return '📅';
      case RentalMode.nights:
        return '🌙';
    }
  }

  static RentalMode fromDb(String? value) {
    switch (value) {
      case 'hours':
        return RentalMode.hours;
      case 'full_day':
        return RentalMode.fullDay;
      case 'nights':
        return RentalMode.nights;
      default:
        return RentalMode.nights;
    }
  }
}

enum CancellationPolicy {
  flexible,
  moderate,
  strict;

  String get label {
    switch (this) {
      case CancellationPolicy.flexible:
        return 'Flexible';
      case CancellationPolicy.moderate:
        return 'Moderada';
      case CancellationPolicy.strict:
        return 'Estricta';
    }
  }

  String get description {
    switch (this) {
      case CancellationPolicy.flexible:
        return 'Cancelación gratis hasta 24h antes';
      case CancellationPolicy.moderate:
        return 'Cancelación gratis hasta 5 días antes';
      case CancellationPolicy.strict:
        return 'Reembolso del 50% hasta 7 días antes';
    }
  }

  static CancellationPolicy fromDb(String? value) {
    switch (value) {
      case 'moderate':
        return CancellationPolicy.moderate;
      case 'strict':
        return CancellationPolicy.strict;
      default:
        return CancellationPolicy.flexible;
    }
  }
}

enum ListingType {
  space,
  experience,
  service;

  String get label {
    switch (this) {
      case ListingType.space:
        return 'Espacio';
      case ListingType.experience:
        return 'Experiencia';
      case ListingType.service:
        return 'Servicio';
    }
  }

  String get icon {
    switch (this) {
      case ListingType.space:
        return '🏠';
      case ListingType.experience:
        return '✨';
      case ListingType.service:
        return '🛠️';
    }
  }
}

enum ListingStatus {
  draft,
  published,
  paused;

  String get label {
    switch (this) {
      case ListingStatus.draft:
        return 'Borrador';
      case ListingStatus.published:
        return 'Publicado';
      case ListingStatus.paused:
        return 'Pausado';
    }
  }
}

enum PriceUnit {
  night,
  hour,
  session,
  person;

  String get label {
    switch (this) {
      case PriceUnit.night:
        return 'noche';
      case PriceUnit.hour:
        return 'hora';
      case PriceUnit.session:
        return 'sesión';
      case PriceUnit.person:
        return 'persona';
    }
  }
}

enum BookingStatus {
  pending,
  confirmed,
  active,
  completed,
  cancelled,
  rejected;

  String get label {
    switch (this) {
      case BookingStatus.pending:
        return 'Pendiente';
      case BookingStatus.confirmed:
        return 'Confirmado';
      case BookingStatus.active:
        return 'Activo';
      case BookingStatus.completed:
        return 'Completado';
      case BookingStatus.cancelled:
        return 'Cancelado';
      case BookingStatus.rejected:
        return 'Rechazado';
    }
  }
}

enum PaymentStatus {
  pending,
  paid,
  refunded;
}

enum KycStatus {
  none,
  pending,
  approved,
  rejected;

  String get label {
    switch (this) {
      case KycStatus.none:
        return 'No verificado';
      case KycStatus.pending:
        return 'En revisión';
      case KycStatus.approved:
        return 'Verificado';
      case KycStatus.rejected:
        return 'Rechazado';
    }
  }
}

enum TransactionType {
  earning,
  payout,
  refund,
  fee;
}

enum MessageType {
  text,
  image,
  system;
}

// === PRICING MODELS ===
enum PricingModel {
  hook1Percent,
  flatFeeCap,
  earlyAdopter;

  String get dbValue {
    switch (this) {
      case PricingModel.hook1Percent:
        return 'HOOK_1_PERCENT';
      case PricingModel.flatFeeCap:
        return 'FLAT_FEE_CAP';
      case PricingModel.earlyAdopter:
        return 'EARLY_ADOPTER';
    }
  }

  String get label {
    switch (this) {
      case PricingModel.hook1Percent:
        return 'Gancho 1%';
      case PricingModel.flatFeeCap:
        return 'Comisión con Tope';
      case PricingModel.earlyAdopter:
        return 'Adoptador Temprano';
    }
  }

  String get description {
    switch (this) {
      case PricingModel.hook1Percent:
        return 'Solo 1% de comisión — quédate con el 99%';
      case PricingModel.flatFeeCap:
        return 'Comisión protegida con tope máximo de \$99';
      case PricingModel.earlyAdopter:
        return 'Comisión progresiva por calidad';
    }
  }

  static PricingModel? fromDb(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'HOOK_1_PERCENT':
        return PricingModel.hook1Percent;
      case 'FLAT_FEE_CAP':
        return PricingModel.flatFeeCap;
      case 'EARLY_ADOPTER':
        return PricingModel.earlyAdopter;
      default:
        return null;
    }
  }
}

// === HOST LEVELS ===
enum HostLevel {
  newHost,
  risingHost,
  proHost,
  eliteHost;

  String get dbValue {
    switch (this) {
      case HostLevel.newHost:
        return 'NEW_HOST';
      case HostLevel.risingHost:
        return 'RISING_HOST';
      case HostLevel.proHost:
        return 'PRO_HOST';
      case HostLevel.eliteHost:
        return 'ELITE_HOST';
    }
  }

  String get label {
    switch (this) {
      case HostLevel.newHost:
        return 'Nuevo Anfitrión';
      case HostLevel.risingHost:
        return 'Anfitrión en Ascenso';
      case HostLevel.proHost:
        return 'Anfitrión Pro';
      case HostLevel.eliteHost:
        return 'Anfitrión Élite';
    }
  }

  int get minBookings {
    switch (this) {
      case HostLevel.newHost:
        return 0;
      case HostLevel.risingHost:
        return 4;
      case HostLevel.proHost:
        return 10;
      case HostLevel.eliteHost:
        return 25;
    }
  }

  HostLevel? get nextLevel {
    switch (this) {
      case HostLevel.newHost:
        return HostLevel.risingHost;
      case HostLevel.risingHost:
        return HostLevel.proHost;
      case HostLevel.proHost:
        return HostLevel.eliteHost;
      case HostLevel.eliteHost:
        return null;
    }
  }

  static HostLevel fromDb(String? value) {
    switch (value) {
      case 'RISING_HOST':
        return HostLevel.risingHost;
      case 'PRO_HOST':
        return HostLevel.proHost;
      case 'ELITE_HOST':
        return HostLevel.eliteHost;
      default:
        return HostLevel.newHost;
    }
  }
}

// === GUEST LEVELS ===
enum GuestLevel {
  explorer,
  regular,
  vip,
  eliteGuest;

  String get dbValue {
    switch (this) {
      case GuestLevel.explorer:
        return 'EXPLORER';
      case GuestLevel.regular:
        return 'REGULAR';
      case GuestLevel.vip:
        return 'VIP';
      case GuestLevel.eliteGuest:
        return 'ELITE_GUEST';
    }
  }

  String get label {
    switch (this) {
      case GuestLevel.explorer:
        return 'Explorador';
      case GuestLevel.regular:
        return 'Regular';
      case GuestLevel.vip:
        return 'VIP';
      case GuestLevel.eliteGuest:
        return 'Usuario Élite';
    }
  }

  int get minBookings {
    switch (this) {
      case GuestLevel.explorer:
        return 0;
      case GuestLevel.regular:
        return 3;
      case GuestLevel.vip:
        return 10;
      case GuestLevel.eliteGuest:
        return 25;
    }
  }

  GuestLevel? get nextLevel {
    switch (this) {
      case GuestLevel.explorer:
        return GuestLevel.regular;
      case GuestLevel.regular:
        return GuestLevel.vip;
      case GuestLevel.vip:
        return GuestLevel.eliteGuest;
      case GuestLevel.eliteGuest:
        return null;
    }
  }

  static GuestLevel fromDb(String? value) {
    switch (value) {
      case 'REGULAR':
        return GuestLevel.regular;
      case 'VIP':
        return GuestLevel.vip;
      case 'ELITE_GUEST':
        return GuestLevel.eliteGuest;
      default:
        return GuestLevel.explorer;
    }
  }
}
