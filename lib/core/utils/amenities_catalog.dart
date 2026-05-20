import 'package:flutter/material.dart';

/// A single amenity option that hosts can attach to a listing.
class AmenitySpec {
  final String key;
  final IconData icon;
  final String label;
  const AmenitySpec(this.key, this.icon, this.label);
}

/// Curated list of amenities a host can pick when creating a listing.
///
/// We store the Spanish label (not the key) in `listings.amenities`
/// because the listing detail screen pattern-matches the label string
/// (e.g. "WiFi", "Estacionamiento") to render the right icon — keeping
/// labels lets old listings keep rendering correctly without a backfill.
class AmenitiesCatalog {
  static const List<AmenitySpec> all = [
    AmenitySpec('wifi', Icons.wifi_rounded, 'WiFi'),
    AmenitySpec('parking', Icons.local_parking_rounded, 'Estacionamiento'),
    AmenitySpec('pool', Icons.pool_rounded, 'Piscina'),
    AmenitySpec('ac', Icons.ac_unit_rounded, 'Aire acondicionado'),
    AmenitySpec('heating', Icons.thermostat_rounded, 'Calefacción'),
    AmenitySpec('kitchen', Icons.kitchen_rounded, 'Cocina equipada'),
    AmenitySpec('tv', Icons.tv_rounded, 'TV'),
    AmenitySpec('jacuzzi', Icons.hot_tub_rounded, 'Jacuzzi'),
    AmenitySpec('view', Icons.landscape_rounded, 'Vista'),
    AmenitySpec('bbq', Icons.outdoor_grill_rounded, 'Quincho / BBQ'),
    AmenitySpec('sound', Icons.speaker_rounded, 'Sonido / Bluetooth'),
    AmenitySpec('gym', Icons.fitness_center_rounded, 'Gimnasio'),
    AmenitySpec('bar', Icons.local_bar_rounded, 'Bar'),
    AmenitySpec('laundry', Icons.local_laundry_service_rounded, 'Lavandería'),
    AmenitySpec('towels', Icons.dry_cleaning_rounded, 'Toallas / Sábanas'),
    AmenitySpec('coffee', Icons.coffee_rounded, 'Cafetera'),
    AmenitySpec('workspace', Icons.work_outline_rounded, 'Espacio de trabajo'),
    AmenitySpec('balcony', Icons.balcony_rounded, 'Balcón / Terraza'),
    AmenitySpec('garden', Icons.grass_rounded, 'Jardín'),
    AmenitySpec('elevator', Icons.elevator_rounded, 'Ascensor'),
    AmenitySpec('petFriendly', Icons.pets_rounded, 'Pet-friendly'),
    AmenitySpec('security', Icons.security_rounded, 'Seguridad 24h'),
    AmenitySpec('smokingArea', Icons.smoking_rooms_rounded, 'Zona de fumadores'),
    AmenitySpec('wheelchair', Icons.accessible_rounded, 'Accesibilidad'),
  ];
}
