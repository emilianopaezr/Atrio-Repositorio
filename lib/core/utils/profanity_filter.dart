/// Lightweight Spanish + English profanity filter used to block obviously
/// abusive text in user-generated short fields (custom amenities, etc.).
///
/// Strategy:
///   • Lower-case + strip diacritics + collapse common leet substitutions
///     so "Pu7@" doesn't slip through.
///   • Word-boundary regex match against a small curated wordlist.
///     Kept short on purpose — overly aggressive lists produce false
///     positives that feel punitive.
///
/// Returns `true` when the text is clean.
class ProfanityFilter {
  static const _blocked = <String>{
    // ── Spanish (general) ────────────────────────────────────
    'puto', 'puta', 'putos', 'putas', 'putear', 'putazo', 'putona', 'putamadre',
    'mierda', 'mierdas',
    'pendejo', 'pendeja', 'pendejos', 'pendejas',
    'cabron', 'cabrones', 'cabrona', 'cabronas',
    'gilipollas', 'gilipolla',
    'cono', 'conazo',
    'joder', 'jodido', 'jodida', 'jodete',
    'imbecil', 'imbeciles',
    'idiota', 'idiotas',
    'estupido', 'estupida', 'estupidos', 'estupidas',
    'chinga', 'chingar', 'chingada', 'chingado', 'chinguen',
    'carajo',
    'maricon', 'maricones', 'marica', 'maricas',
    'chupala', 'chupame', 'chupalo',
    'verga', 'vergas',
    'culero', 'culeros',
    'pelotudo', 'pelotuda', 'pelotudos',
    'boludo', 'boluda', 'boludos', 'boludas',
    'weon', 'weona', 'weones', 'weas',
    'ctm', 'ctmre', 'conchatumadre', 'conchasumadre', 'conchadetumadre',
    'forro', 'forra',
    'sorete', 'soretes',
    'folla', 'follar', 'follador', 'follame',
    'cojer', 'cojerla', 'cojerme',
    'mamon', 'mamones',
    // ── English ──────────────────────────────────────────────
    'fuck', 'fucking', 'fucked', 'fucker',
    'shit', 'shitty',
    'asshole', 'assholes',
    'bitch', 'bitches',
    'cunt', 'cunts',
    'dick', 'dickhead',
    'whore', 'slut',
    'bastard',
    'motherfucker',
    // ── Slurs / hate (any language) — non-negotiable block ──
    'nigger', 'nigga', 'niggas',
    'kike', 'spic', 'chink',
    'sudaca',
    'nazi', 'nazis', 'hitler', 'kkk',
    'retard', 'retardado',
    'faggot', 'fag',
  };

  /// True when [text] does not contain any blocked term.
  static bool isClean(String text) {
    if (text.trim().isEmpty) return true;
    final n = _normalize(text);
    for (final w in _blocked) {
      final re = RegExp(r'\b' + RegExp.escape(w) + r'\b');
      if (re.hasMatch(n)) return false;
    }
    return true;
  }

  /// Lower-case, strip diacritics, replace common leet substitutions.
  /// Word boundaries are preserved so "computar" doesn't false-match "puta".
  static String _normalize(String s) {
    var t = s.toLowerCase();
    const dia = {
      'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ñ': 'n',
      'à': 'a', 'è': 'e', 'ì': 'i', 'ò': 'o', 'ù': 'u',
    };
    dia.forEach((k, v) => t = t.replaceAll(k, v));
    const leet = {
      '0': 'o', '1': 'i', '3': 'e', '4': 'a',
      '5': 's', '7': 't', r'$': 's', '@': 'a',
    };
    leet.forEach((k, v) => t = t.replaceAll(k, v));
    return t;
  }
}
