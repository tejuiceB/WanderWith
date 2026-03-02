/// Static emergency number database for 60+ countries.
/// Fallback chain: AI data → this database → '112' (universal last resort).
///
/// Sources: ITU, Wikipedia "List of emergency telephone numbers",
/// respective government websites. Data accurate as of June 2025.

class EmergencyNumbers {
  final String police;
  final String ambulance;
  final String fire;
  final String? generalEmergency; // If one number covers all

  const EmergencyNumbers({
    required this.police,
    required this.ambulance,
    required this.fire,
    this.generalEmergency,
  });
}

class EmergencyNumbersDB {
  EmergencyNumbersDB._();

  /// Look up emergency numbers by ISO 3166-1 alpha-2 country code (lowercase).
  /// Returns null if country not in database.
  static EmergencyNumbers? lookup(String? countryCode) {
    if (countryCode == null || countryCode.isEmpty) return null;
    final code = countryCode.toLowerCase().trim();
    // Try direct code lookup first
    if (_data.containsKey(code)) return _data[code];
    // Try name → code mapping
    final mapped = _nameToCode[code];
    if (mapped != null) return _data[mapped];
    return null;
  }

  /// Extract country from a location string like "Tokyo, Japan" and look up numbers.
  static EmergencyNumbers? lookupFromLocation(String? location) {
    if (location == null || location.isEmpty) return null;
    // Try the last comma-separated part (usually the country)
    final parts = location.split(',').map((s) => s.trim().toLowerCase()).toList();
    for (final part in parts.reversed) {
      if (part.isEmpty) continue;
      // Direct code match
      if (_data.containsKey(part)) return _data[part];
      // Name match
      final code = _nameToCode[part];
      if (code != null) return _data[code];
    }
    return null;
  }

  /// Get country code from a location string like "Tokyo, Japan" → "jp"
  static String? countryCodeFromLocation(String? location) {
    if (location == null || location.isEmpty) return null;
    final parts = location.split(',').map((s) => s.trim().toLowerCase()).toList();
    for (final part in parts.reversed) {
      if (part.isEmpty) continue;
      if (_data.containsKey(part)) return part;
      final code = _nameToCode[part];
      if (code != null) return code;
    }
    return null;
  }

  /// Get police number for a country with fallback.
  static String policeNumber(String? countryCode, [String fallback = '112']) {
    return lookup(countryCode)?.police ?? fallback;
  }

  /// Get ambulance number for a country with fallback.
  static String ambulanceNumber(String? countryCode, [String fallback = '112']) {
    return lookup(countryCode)?.ambulance ?? fallback;
  }

  /// Get fire number for a country with fallback.
  static String fireNumber(String? countryCode, [String fallback = '112']) {
    return lookup(countryCode)?.fire ?? fallback;
  }

  /// Get general emergency number for a country with fallback.
  static String generalNumber(String? countryCode, [String fallback = '112']) {
    final entry = lookup(countryCode);
    return entry?.generalEmergency ?? entry?.police ?? fallback;
  }

  static const Map<String, EmergencyNumbers> _data = {
    // ─── Americas ──────────────────────────────────────────
    'us': EmergencyNumbers(police: '911', ambulance: '911', fire: '911', generalEmergency: '911'),
    'ca': EmergencyNumbers(police: '911', ambulance: '911', fire: '911', generalEmergency: '911'),
    'mx': EmergencyNumbers(police: '911', ambulance: '911', fire: '911', generalEmergency: '911'),
    'br': EmergencyNumbers(police: '190', ambulance: '192', fire: '193'),
    'ar': EmergencyNumbers(police: '911', ambulance: '107', fire: '100', generalEmergency: '911'),
    'cl': EmergencyNumbers(police: '133', ambulance: '131', fire: '132'),
    'co': EmergencyNumbers(police: '123', ambulance: '123', fire: '123', generalEmergency: '123'),
    'pe': EmergencyNumbers(police: '105', ambulance: '116', fire: '116'),
    'ec': EmergencyNumbers(police: '911', ambulance: '911', fire: '911', generalEmergency: '911'),
    'cr': EmergencyNumbers(police: '911', ambulance: '911', fire: '911', generalEmergency: '911'),
    'pa': EmergencyNumbers(police: '104', ambulance: '911', fire: '103'),
    'jm': EmergencyNumbers(police: '119', ambulance: '110', fire: '110'),
    'tt': EmergencyNumbers(police: '999', ambulance: '990', fire: '990'),
    'do': EmergencyNumbers(police: '911', ambulance: '911', fire: '911', generalEmergency: '911'),
    'cu': EmergencyNumbers(police: '106', ambulance: '104', fire: '105'),
    'uy': EmergencyNumbers(police: '911', ambulance: '105', fire: '104'),
    've': EmergencyNumbers(police: '171', ambulance: '171', fire: '171', generalEmergency: '171'),
    'bo': EmergencyNumbers(police: '110', ambulance: '118', fire: '119'),
    'py': EmergencyNumbers(police: '911', ambulance: '141', fire: '132'),
    'gt': EmergencyNumbers(police: '110', ambulance: '123', fire: '123'),
    'hn': EmergencyNumbers(police: '199', ambulance: '195', fire: '198'),

    // ─── Europe ────────────────────────────────────────────
    'gb': EmergencyNumbers(police: '999', ambulance: '999', fire: '999', generalEmergency: '999'),
    'de': EmergencyNumbers(police: '110', ambulance: '112', fire: '112'),
    'fr': EmergencyNumbers(police: '17', ambulance: '15', fire: '18', generalEmergency: '112'),
    'it': EmergencyNumbers(police: '113', ambulance: '118', fire: '115', generalEmergency: '112'),
    'es': EmergencyNumbers(police: '091', ambulance: '061', fire: '080', generalEmergency: '112'),
    'pt': EmergencyNumbers(police: '112', ambulance: '112', fire: '112', generalEmergency: '112'),
    'nl': EmergencyNumbers(police: '112', ambulance: '112', fire: '112', generalEmergency: '112'),
    'be': EmergencyNumbers(police: '101', ambulance: '112', fire: '112', generalEmergency: '112'),
    'ch': EmergencyNumbers(police: '117', ambulance: '144', fire: '118'),
    'at': EmergencyNumbers(police: '133', ambulance: '144', fire: '122', generalEmergency: '112'),
    'se': EmergencyNumbers(police: '112', ambulance: '112', fire: '112', generalEmergency: '112'),
    'no': EmergencyNumbers(police: '112', ambulance: '113', fire: '110'),
    'dk': EmergencyNumbers(police: '112', ambulance: '112', fire: '112', generalEmergency: '112'),
    'fi': EmergencyNumbers(police: '112', ambulance: '112', fire: '112', generalEmergency: '112'),
    'ie': EmergencyNumbers(police: '112', ambulance: '112', fire: '112', generalEmergency: '112'),
    'pl': EmergencyNumbers(police: '997', ambulance: '999', fire: '998', generalEmergency: '112'),
    'cz': EmergencyNumbers(police: '158', ambulance: '155', fire: '150', generalEmergency: '112'),
    'gr': EmergencyNumbers(police: '100', ambulance: '166', fire: '199', generalEmergency: '112'),
    'hu': EmergencyNumbers(police: '107', ambulance: '104', fire: '105', generalEmergency: '112'),
    'ro': EmergencyNumbers(police: '112', ambulance: '112', fire: '112', generalEmergency: '112'),
    'bg': EmergencyNumbers(police: '166', ambulance: '150', fire: '160', generalEmergency: '112'),
    'hr': EmergencyNumbers(police: '192', ambulance: '194', fire: '193', generalEmergency: '112'),
    'sk': EmergencyNumbers(police: '158', ambulance: '155', fire: '150', generalEmergency: '112'),
    'si': EmergencyNumbers(police: '113', ambulance: '112', fire: '112', generalEmergency: '112'),
    'rs': EmergencyNumbers(police: '192', ambulance: '194', fire: '193'),
    'ua': EmergencyNumbers(police: '102', ambulance: '103', fire: '101', generalEmergency: '112'),
    'is': EmergencyNumbers(police: '112', ambulance: '112', fire: '112', generalEmergency: '112'),
    'lu': EmergencyNumbers(police: '113', ambulance: '112', fire: '112', generalEmergency: '112'),
    'ee': EmergencyNumbers(police: '112', ambulance: '112', fire: '112', generalEmergency: '112'),
    'lv': EmergencyNumbers(police: '112', ambulance: '113', fire: '112', generalEmergency: '112'),
    'lt': EmergencyNumbers(police: '112', ambulance: '112', fire: '112', generalEmergency: '112'),

    // ─── Asia ──────────────────────────────────────────────
    'in': EmergencyNumbers(police: '100', ambulance: '108', fire: '101', generalEmergency: '112'),
    'cn': EmergencyNumbers(police: '110', ambulance: '120', fire: '119'),
    'jp': EmergencyNumbers(police: '110', ambulance: '119', fire: '119'),
    'kr': EmergencyNumbers(police: '112', ambulance: '119', fire: '119'),
    'th': EmergencyNumbers(police: '191', ambulance: '1669', fire: '199', generalEmergency: '191'),
    'sg': EmergencyNumbers(police: '999', ambulance: '995', fire: '995'),
    'my': EmergencyNumbers(police: '999', ambulance: '999', fire: '994'),
    'id': EmergencyNumbers(police: '110', ambulance: '118', fire: '113', generalEmergency: '112'),
    'ph': EmergencyNumbers(police: '911', ambulance: '911', fire: '911', generalEmergency: '911'),
    'vn': EmergencyNumbers(police: '113', ambulance: '115', fire: '114'),
    'bd': EmergencyNumbers(police: '999', ambulance: '999', fire: '999', generalEmergency: '999'),
    'pk': EmergencyNumbers(police: '15', ambulance: '115', fire: '16', generalEmergency: '1122'),
    'lk': EmergencyNumbers(police: '119', ambulance: '110', fire: '110'),
    'np': EmergencyNumbers(police: '100', ambulance: '102', fire: '101'),
    'mm': EmergencyNumbers(police: '199', ambulance: '192', fire: '191'),
    'kh': EmergencyNumbers(police: '117', ambulance: '119', fire: '118'),
    'tw': EmergencyNumbers(police: '110', ambulance: '119', fire: '119'),
    'hk': EmergencyNumbers(police: '999', ambulance: '999', fire: '999', generalEmergency: '999'),
    'mo': EmergencyNumbers(police: '999', ambulance: '999', fire: '999', generalEmergency: '999'),
    'mn': EmergencyNumbers(police: '102', ambulance: '103', fire: '101'),

    // ─── Middle East ───────────────────────────────────────
    'ae': EmergencyNumbers(police: '999', ambulance: '998', fire: '997'),
    'sa': EmergencyNumbers(police: '999', ambulance: '997', fire: '998'),
    'qa': EmergencyNumbers(police: '999', ambulance: '999', fire: '999', generalEmergency: '999'),
    'kw': EmergencyNumbers(police: '112', ambulance: '112', fire: '112', generalEmergency: '112'),
    'bh': EmergencyNumbers(police: '999', ambulance: '999', fire: '999', generalEmergency: '999'),
    'om': EmergencyNumbers(police: '9999', ambulance: '9999', fire: '9999', generalEmergency: '9999'),
    'jo': EmergencyNumbers(police: '911', ambulance: '911', fire: '911', generalEmergency: '911'),
    'lb': EmergencyNumbers(police: '112', ambulance: '140', fire: '175', generalEmergency: '112'),
    'il': EmergencyNumbers(police: '100', ambulance: '101', fire: '102'),
    'tr': EmergencyNumbers(police: '155', ambulance: '112', fire: '110', generalEmergency: '112'),
    'iq': EmergencyNumbers(police: '104', ambulance: '122', fire: '115'),
    'ir': EmergencyNumbers(police: '110', ambulance: '115', fire: '125'),
    'eg': EmergencyNumbers(police: '122', ambulance: '123', fire: '180'),

    // ─── Africa ────────────────────────────────────────────
    'za': EmergencyNumbers(police: '10111', ambulance: '10177', fire: '10177', generalEmergency: '112'),
    'ng': EmergencyNumbers(police: '112', ambulance: '112', fire: '112', generalEmergency: '112'),
    'ke': EmergencyNumbers(police: '999', ambulance: '999', fire: '999', generalEmergency: '999'),
    'tz': EmergencyNumbers(police: '112', ambulance: '114', fire: '112', generalEmergency: '112'),
    'gh': EmergencyNumbers(police: '191', ambulance: '193', fire: '192'),
    'et': EmergencyNumbers(police: '991', ambulance: '907', fire: '939'),
    'ma': EmergencyNumbers(police: '19', ambulance: '15', fire: '15'),
    'tn': EmergencyNumbers(police: '197', ambulance: '190', fire: '198'),
    'rw': EmergencyNumbers(police: '112', ambulance: '912', fire: '112', generalEmergency: '112'),
    'mu': EmergencyNumbers(police: '999', ambulance: '114', fire: '115'),
    'ug': EmergencyNumbers(police: '999', ambulance: '911', fire: '999'),

    // ─── Oceania ───────────────────────────────────────────
    'au': EmergencyNumbers(police: '000', ambulance: '000', fire: '000', generalEmergency: '000'),
    'nz': EmergencyNumbers(police: '111', ambulance: '111', fire: '111', generalEmergency: '111'),
    'fj': EmergencyNumbers(police: '917', ambulance: '911', fire: '910'),

    // ─── Central & South Asia ──────────────────────────────
    'kz': EmergencyNumbers(police: '102', ambulance: '103', fire: '101'),
    'uz': EmergencyNumbers(police: '102', ambulance: '103', fire: '101'),
    'ge': EmergencyNumbers(police: '112', ambulance: '112', fire: '112', generalEmergency: '112'),
    'am': EmergencyNumbers(police: '102', ambulance: '103', fire: '101'),
    'az': EmergencyNumbers(police: '102', ambulance: '103', fire: '101'),
  };

  /// Country name → ISO code mapping for robust lookups
  static const Map<String, String> _nameToCode = {
    'india': 'in', 'china': 'cn', 'japan': 'jp', 'south korea': 'kr', 'korea': 'kr',
    'thailand': 'th', 'singapore': 'sg', 'malaysia': 'my', 'indonesia': 'id',
    'philippines': 'ph', 'vietnam': 'vn', 'bangladesh': 'bd', 'pakistan': 'pk',
    'sri lanka': 'lk', 'nepal': 'np', 'myanmar': 'mm', 'cambodia': 'kh',
    'taiwan': 'tw', 'hong kong': 'hk', 'macau': 'mo', 'mongolia': 'mn',
    'united states': 'us', 'usa': 'us', 'america': 'us', 'united states of america': 'us',
    'canada': 'ca', 'mexico': 'mx', 'brazil': 'br', 'argentina': 'ar',
    'chile': 'cl', 'colombia': 'co', 'peru': 'pe', 'ecuador': 'ec',
    'costa rica': 'cr', 'panama': 'pa', 'jamaica': 'jm', 'cuba': 'cu',
    'uruguay': 'uy', 'venezuela': 've', 'dominican republic': 'do',
    'united kingdom': 'gb', 'uk': 'gb', 'england': 'gb', 'scotland': 'gb', 'wales': 'gb',
    'france': 'fr', 'germany': 'de', 'italy': 'it', 'spain': 'es',
    'portugal': 'pt', 'netherlands': 'nl', 'holland': 'nl', 'belgium': 'be',
    'switzerland': 'ch', 'austria': 'at', 'sweden': 'se', 'norway': 'no',
    'denmark': 'dk', 'finland': 'fi', 'ireland': 'ie', 'poland': 'pl',
    'czech republic': 'cz', 'czechia': 'cz', 'hungary': 'hu', 'romania': 'ro',
    'greece': 'gr', 'croatia': 'hr', 'bulgaria': 'bg', 'slovakia': 'sk',
    'slovenia': 'si', 'serbia': 'rs', 'ukraine': 'ua', 'iceland': 'is',
    'luxembourg': 'lu', 'estonia': 'ee', 'latvia': 'lv', 'lithuania': 'lt',
    'united arab emirates': 'ae', 'uae': 'ae', 'dubai': 'ae', 'abu dhabi': 'ae',
    'saudi arabia': 'sa', 'qatar': 'qa', 'kuwait': 'kw', 'bahrain': 'bh',
    'oman': 'om', 'jordan': 'jo', 'lebanon': 'lb', 'israel': 'il',
    'turkey': 'tr', 'türkiye': 'tr', 'iraq': 'iq', 'iran': 'ir', 'egypt': 'eg',
    'south africa': 'za', 'nigeria': 'ng', 'kenya': 'ke', 'tanzania': 'tz',
    'ghana': 'gh', 'ethiopia': 'et', 'morocco': 'ma', 'tunisia': 'tn',
    'rwanda': 'rw', 'mauritius': 'mu', 'uganda': 'ug',
    'australia': 'au', 'new zealand': 'nz', 'fiji': 'fj',
    'kazakhstan': 'kz', 'uzbekistan': 'uz', 'georgia': 'ge', 'armenia': 'am',
    'azerbaijan': 'az', 'russia': 'ru', 'maldives': 'mv', 'bhutan': 'bt',
  };
}
