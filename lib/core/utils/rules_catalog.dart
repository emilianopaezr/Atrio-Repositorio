import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class RuleSpec {
  final String key;
  final IconData icon;
  const RuleSpec(this.key, this.icon);
}

class RulesCatalog {
  static const List<RuleSpec> all = [
    RuleSpec('no_smoking', Icons.smoke_free_rounded),
    RuleSpec('no_pets', Icons.pets_rounded),
    RuleSpec('pets_allowed', Icons.pets_outlined),
    RuleSpec('no_parties', Icons.celebration_rounded),
    RuleSpec('no_kids', Icons.child_friendly_rounded),
    RuleSpec('quiet_hours', Icons.nightlight_round),
    RuleSpec('no_shoes', Icons.do_not_step_rounded),
    RuleSpec('no_food', Icons.no_food_rounded),
    RuleSpec('no_extra_guests', Icons.person_off_rounded),
    RuleSpec('no_filming', Icons.videocam_off_rounded),
    RuleSpec('no_loud_music', Icons.music_off_rounded),
    RuleSpec('respect_neighbors', Icons.front_hand_rounded),
  ];

  static RuleSpec? specFor(String key) {
    for (final s in all) {
      if (s.key == key) return s;
    }
    return null;
  }

  static String label(BuildContext context, String key) {
    final l = AppLocalizations.of(context);
    switch (key) {
      case 'no_smoking':
        return l.ruleNoSmoking;
      case 'no_pets':
        return l.ruleNoPets;
      case 'pets_allowed':
        return l.rulePetsAllowed;
      case 'no_parties':
        return l.ruleNoParties;
      case 'no_kids':
        return l.ruleNoKids;
      case 'quiet_hours':
        return l.ruleQuietHours;
      case 'no_shoes':
        return l.ruleNoShoes;
      case 'no_food':
        return l.ruleNoFood;
      case 'no_extra_guests':
        return l.ruleNoExtraGuests;
      case 'no_filming':
        return l.ruleNoFilming;
      case 'no_loud_music':
        return l.ruleNoLoudMusic;
      case 'respect_neighbors':
        return l.ruleRespectNeighbors;
      default:
        return key;
    }
  }

  static IconData icon(String key) =>
      specFor(key)?.icon ?? Icons.check_circle_outline_rounded;
}
