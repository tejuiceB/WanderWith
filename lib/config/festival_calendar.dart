/// Country-aware festival calendar for travel-season notifications.
///
/// Each festival entry defines the country, name, approximate date range,
/// and a set of multilingual notification messages (keyed by language code).
///
/// Used by the smart-notifications Edge Function to send festival
/// notifications 7-10 days before the event — only to users in the
/// matching country who don't already have a trip planned for that period.
class FestivalCalendar {
  FestivalCalendar._();

  /// Returns festivals matching [countryCode] that fall within the next
  /// [lookAheadDays] (default 10) from [now].
  static List<Festival> upcoming(String countryCode, {DateTime? now, int lookAheadDays = 10}) {
    final ref = now ?? DateTime.now();
    final year = ref.year;
    final results = <Festival>[];

    for (final f in _festivals) {
      if (f.country != countryCode) continue;
      // Resolve date for the current year
      final resolved = f.resolveDate(year);
      if (resolved == null) continue;
      final diff = resolved.difference(ref).inDays;
      if (diff >= 0 && diff <= lookAheadDays) {
        results.add(f);
      }
    }
    return results;
  }

  /// All known festivals.
  static List<Festival> get all => List.unmodifiable(_festivals);

  // ── Festival database ─────────────────────────────────────────────
  static final List<Festival> _festivals = [
    // 🇮🇳 India
    Festival(
      country: 'IN',
      name: 'Diwali',
      month: 10, day: 25, // ≈ Oct-Nov — approximate, shifts yearly
      messages: {
        'en': 'Diwali long weekend? Plan a getaway 🪔',
        'hi': 'दिवाली की छुट्टियां? कहीं घूमने चलें 🪔',
        'mr': 'दिवाळीची सुट्टी? कुठेतरी फिरायला जा 🪔',
      },
    ),
    Festival(
      country: 'IN',
      name: 'Holi',
      month: 3, day: 14,
      messages: {
        'en': 'Holi in Mathura? Book before it\'s too late 🎨',
        'hi': 'मथुरा में होली? जल्दी बुक करो 🎨',
        'mr': 'मथुरामध्ये होळी? लवकर बुक करा 🎨',
      },
    ),
    Festival(
      country: 'IN',
      name: 'New Year',
      month: 12, day: 28,
      messages: {
        'en': 'Goa calling for New Year 🎊',
        'hi': 'न्यू ईयर के लिए गोवा चलें? 🎊',
        'mr': 'नवीन वर्षासाठी गोवा? 🎊',
      },
    ),
    Festival(
      country: 'IN',
      name: 'Independence Day',
      month: 8, day: 15,
      messages: {
        'en': 'Independence Day weekend trip? 🇮🇳',
        'hi': 'स्वतंत्रता दिवस पर कहीं घूमें? 🇮🇳',
        'mr': 'स्वातंत्र्य दिनी कुठे फिरायचे? 🇮🇳',
      },
    ),
    Festival(
      country: 'IN',
      name: 'Ganesh Chaturthi',
      month: 9, day: 5,
      messages: {
        'en': 'Ganpati Bappa Morya! Plan a trip to Konkan 🐘',
        'hi': 'गणपति बप्पा मोरया! कोंकण चलें? 🐘',
        'mr': 'गणपती बाप्पा मोरया! कोकणात जायचं? 🐘',
      },
    ),

    // 🇺🇸 USA
    Festival(
      country: 'US',
      name: 'Thanksgiving',
      month: 11, day: 23, // ≈ 4th Thursday of November
      messages: {
        'en': 'Thanksgiving getaway ideas 🦃',
        'es': 'Ideas para escapada de Acción de Gracias 🦃',
      },
    ),
    Festival(
      country: 'US',
      name: 'Spring Break',
      month: 3, day: 15,
      messages: {
        'en': 'Spring break is coming — where to? 🌴',
        'es': 'Las vacaciones de primavera se acercan — ¿a dónde? 🌴',
      },
    ),
    Festival(
      country: 'US',
      name: 'Independence Day',
      month: 7, day: 4,
      messages: {
        'en': '4th of July road trip? 🇺🇸🎆',
        'es': '¿Viaje por carretera el 4 de julio? 🇺🇸🎆',
      },
    ),
    Festival(
      country: 'US',
      name: 'Memorial Day',
      month: 5, day: 27,
      messages: {
        'en': 'Memorial Day weekend — perfect for a quick trip 🏖',
      },
    ),

    // 🇯🇵 Japan
    Festival(
      country: 'JP',
      name: 'Cherry Blossom',
      month: 3, day: 25,
      messages: {
        'en': 'Cherry blossom season is here 🌸',
        'ja': '桜の季節がやってきました 🌸',
      },
    ),
    Festival(
      country: 'JP',
      name: 'Golden Week',
      month: 4, day: 29,
      messages: {
        'en': 'Golden Week is coming — plan your trip! 🗾',
        'ja': 'ゴールデンウィークが近づいてます — 旅行を計画しよう！🗾',
      },
    ),
    Festival(
      country: 'JP',
      name: 'Obon',
      month: 8, day: 13,
      messages: {
        'en': 'Obon holiday — time for a getaway 🏯',
        'ja': 'お盆休み — どこかに行きませんか 🏯',
      },
    ),

    // 🇬🇧 UK
    Festival(
      country: 'GB',
      name: 'May Bank Holiday',
      month: 5, day: 6,
      messages: {
        'en': 'Bank holiday weekend trip? 🇬🇧',
      },
    ),
    Festival(
      country: 'GB',
      name: 'August Bank Holiday',
      month: 8, day: 26,
      messages: {
        'en': 'August bank holiday — last summer trip? ☀️',
      },
    ),

    // 🇫🇷 France
    Festival(
      country: 'FR',
      name: 'Bastille Day',
      month: 7, day: 14,
      messages: {
        'en': 'Long weekend — time for a French road trip 🇫🇷',
        'fr': 'Pont du 14 juillet — road trip en France ? 🇫🇷',
      },
    ),

    // 🇧🇷 Brazil
    Festival(
      country: 'BR',
      name: 'Carnaval',
      month: 2, day: 20,
      messages: {
        'en': 'Carnival is almost here! Plan your trip 🎭',
        'pt': 'O Carnaval está chegando! Planeje sua viagem 🎭',
      },
    ),

    // 🇩🇪 Germany
    Festival(
      country: 'DE',
      name: 'Oktoberfest',
      month: 9, day: 16,
      messages: {
        'en': 'Oktoberfest is coming — Munich trip anyone? 🍺',
        'de': 'Oktoberfest steht vor der Tür — ab nach München? 🍺',
      },
    ),
    Festival(
      country: 'DE',
      name: 'Christmas Markets',
      month: 12, day: 1,
      messages: {
        'en': 'Christmas market season! Visit a German Weihnachtsmarkt 🎄',
        'de': 'Weihnachtsmarkt-Saison! Los geht\'s 🎄',
      },
    ),

    // 🇪🇸 Spain
    Festival(
      country: 'ES',
      name: 'La Tomatina',
      month: 8, day: 28,
      messages: {
        'en': 'La Tomatina is this week — road trip to Buñol? 🍅',
        'es': '¡La Tomatina es esta semana — viaje a Buñol? 🍅',
      },
    ),
  ];
}

/// A single festival entry.
class Festival {
  final String country;  // ISO 3166-1 alpha-2
  final String name;
  final int month;       // 1-12
  final int day;         // Approximate day of month
  final Map<String, String> messages; // lang → notification text

  const Festival({
    required this.country,
    required this.name,
    required this.month,
    required this.day,
    required this.messages,
  });

  /// Resolve the festival's date for a given [year].
  DateTime? resolveDate(int year) {
    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  /// Get message in preferred language (falls back to English).
  String getMessage(String lang) {
    return messages[lang] ?? messages['en'] ?? messages.values.first;
  }
}
