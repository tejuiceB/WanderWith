/// Pre-translated notification templates for 8 supported languages.
///
/// Template variables: {destination}, {days}, {name}, {trip_name},
/// {temp}, {condition}, {unchecked}, {day_num}, {time}.
/// Use [NotificationTemplates.get] to resolve a template by key + language.
class NotificationTemplates {
  NotificationTemplates._();

  // ── Supported languages ───────────────────────────────────────────
  static const supportedLanguages = {
    'en': 'English',
    'hi': 'Hindi',
    'mr': 'Marathi',
    'es': 'Spanish',
    'fr': 'French',
    'ja': 'Japanese',
    'pt': 'Portuguese',
    'de': 'German',
  };

  /// Resolve a template. Returns English fallback if language key is missing.
  static String get(String key, String lang, [Map<String, String> vars = const {}]) {
    final langMap = _templates[key];
    if (langMap == null) return key; // unknown key
    String tpl = langMap[lang] ?? langMap['en'] ?? key;
    vars.forEach((k, v) => tpl = tpl.replaceAll('{$k}', v));
    return tpl;
  }

  // ── Template map ──────────────────────────────────────────────────
  static const Map<String, Map<String, String>> _templates = {

    // ── Trip Lifecycle: Before trip ─────────────────────────────────
    'trip_starting_7d': {
      'en': '🧳 Packing reminder: {destination} in 1 week!',
      'hi': '🧳 पैकिंग रिमाइंडर: {destination} सिर्फ 1 हफ्ते में!',
      'mr': '🧳 पॅकिंग रिमाइंडर: {destination} 1 आठवड्यात!',
      'es': '🧳 ¡Recuerda empacar! {destination} en 1 semana',
      'fr': '🧳 Rappel de valise : {destination} dans 1 semaine !',
      'ja': '🧳 荷造りリマインダー：{destination}まであと1週間！',
      'pt': '🧳 Lembrete: {destination} em 1 semana!',
      'de': '🧳 Packen nicht vergessen: {destination} in 1 Woche!',
    },
    'trip_starting_3d': {
      'en': '🌤 Weather alert: {destination} will be {temp}° — pack accordingly',
      'hi': '🌤 मौसम अलर्ट: {destination} में {temp}° रहेगा — सोच-समझकर पैक करें',
      'mr': '🌤 हवामान अलर्ट: {destination} मध्ये {temp}° — त्यानुसार पॅक करा',
      'es': '🌤 Alerta meteorológica: {destination} estará a {temp}° — prepárate',
      'fr': '🌤 Alerte météo : {destination} fera {temp}° — préparez-vous',
      'ja': '🌤 天気予報：{destination}は{temp}°になります — 準備しましょう',
      'pt': '🌤 Alerta de clima: {destination} estará {temp}° — prepare-se',
      'de': '🌤 Wetterwarnung: {destination} wird {temp}° — pack entsprechend',
    },
    'trip_starting_1d': {
      'en': '🚨 {destination} trip starts tomorrow! All set?',
      'hi': '🚨 {destination} ट्रिप कल शुरू! सब तैयार?',
      'mr': '🚨 {destination} ट्रिप उद्या सुरू! सर्व तयार?',
      'es': '🚨 ¡Tu viaje a {destination} empieza mañana! ¿Todo listo?',
      'fr': '🚨 Votre voyage à {destination} commence demain ! Tout est prêt ?',
      'ja': '🚨 {destination}旅行は明日出発！準備はOK？',
      'pt': '🚨 Sua viagem para {destination} começa amanhã! Tudo pronto?',
      'de': '🚨 Deine {destination}-Reise beginnt morgen! Alles bereit?',
    },
    'checklist_unchecked': {
      'en': '📋 Checklist check: {unchecked} items still unchecked for {destination}',
      'hi': '📋 चेकलिस्ट: {destination} के लिए {unchecked} आइटम अभी बाकी',
      'mr': '📋 चेकलिस्ट: {destination} साठी {unchecked} आयटम बाकी',
      'es': '📋 Lista: {unchecked} pendientes para {destination}',
      'fr': '📋 Checklist : {unchecked} éléments restants pour {destination}',
      'ja': '📋 チェックリスト：{destination}の{unchecked}件が未チェック',
      'pt': '📋 Checklist: {unchecked} itens pendentes para {destination}',
      'de': '📋 Checkliste: {unchecked} offene Punkte für {destination}',
    },

    // ── Trip Lifecycle: During trip ─────────────────────────────────
    'trip_start_day': {
      'en': '🎉 Your {destination} trip starts today! Have an amazing time',
      'hi': '🎉 आपकी {destination} ट्रिप आज शुरू! शानदार समय बिताइए',
      'mr': '🎉 तुमची {destination} ट्रिप आज सुरू! मजा करा',
      'es': '🎉 ¡Tu viaje a {destination} empieza hoy! Disfrútalo',
      'fr': '🎉 Votre voyage à {destination} commence aujourd\'hui ! Profitez bien',
      'ja': '🎉 {destination}旅行は今日スタート！素晴らしい時間を',
      'pt': '🎉 Sua viagem para {destination} começa hoje! Aproveite',
      'de': '🎉 Deine {destination}-Reise beginnt heute! Viel Spaß',
    },
    'daily_plan': {
      'en': '📍 Day {day_num} in {destination}! Check today\'s plan',
      'hi': '📍 {destination} में दिन {day_num}! आज का प्लान देखें',
      'mr': '📍 {destination} मध्ये दिवस {day_num}! आजचा प्लॅन पहा',
      'es': '📍 ¡Día {day_num} en {destination}! Revisa el plan',
      'fr': '📍 Jour {day_num} à {destination} ! Consultez le programme',
      'ja': '📍 {destination}{day_num}日目！今日のプランを確認',
      'pt': '📍 Dia {day_num} em {destination}! Veja o plano',
      'de': '📍 Tag {day_num} in {destination}! Tagesprogramm ansehen',
    },

    // ── Trip Lifecycle: After trip ──────────────────────────────────
    'trip_ended_1d': {
      'en': '📸 Relive your {destination} memories',
      'hi': '📸 {destination} की यादें फिर से जीएं',
      'mr': '📸 {destination} च्या आठवणी पुन्हा अनुभवा',
      'es': '📸 Revive tus recuerdos de {destination}',
      'fr': '📸 Revivez vos souvenirs de {destination}',
      'ja': '📸 {destination}の思い出を振り返ろう',
      'pt': '📸 Reviva suas memórias de {destination}',
      'de': '📸 Erlebe deine {destination}-Erinnerungen nochmal',
    },
    'trip_ended_3d': {
      'en': '✍️ Share your {destination} experience — create a highlight post',
      'hi': '✍️ {destination} का अनुभव शेयर करें — हाइलाइट पोस्ट बनाएं',
      'mr': '✍️ {destination} चा अनुभव शेअर करा — हायलाइट पोस्ट बनवा',
      'es': '✍️ Comparte tu experiencia en {destination} — crea una publicación',
      'fr': '✍️ Partagez votre expérience à {destination} — créez un post',
      'ja': '✍️ {destination}の体験をシェア — ハイライト投稿を作成',
      'pt': '✍️ Compartilhe sua experiência em {destination} — crie um post',
      'de': '✍️ Teile dein {destination}-Erlebnis — erstelle einen Highlight-Post',
    },
    'trip_ended_7d': {
      'en': '⭐ Rate your {destination} trip and help others',
      'hi': '⭐ {destination} ट्रिप को रेट करें और दूसरों की मदद करें',
      'mr': '⭐ {destination} ट्रिपला रेट करा आणि इतरांना मदत करा',
      'es': '⭐ Califica tu viaje a {destination} y ayuda a otros',
      'fr': '⭐ Notez votre voyage à {destination} et aidez les autres',
      'ja': '⭐ {destination}旅行を評価して他の人を助けよう',
      'pt': '⭐ Avalie sua viagem para {destination} e ajude outros',
      'de': '⭐ Bewerte deine {destination}-Reise und hilf anderen',
    },

    // ── Weather alerts ──────────────────────────────────────────────
    'weather_rain': {
      'en': '🌧️ Heavy rain expected during your {destination} trip — plan indoor activities?',
      'hi': '🌧️ {destination} ट्रिप में भारी बारिश — इनडोर प्लान बनाएं?',
      'mr': '🌧️ {destination} ट्रिपमध्ये जोरदार पाऊस — इनडोअर प्लॅन करा?',
      'es': '🌧️ Lluvia fuerte prevista en {destination} — ¿planes bajo techo?',
      'fr': '🌧️ Fortes pluies prévues à {destination} — activités intérieures ?',
      'ja': '🌧️ {destination}で大雨の予報 — 室内プランを考えましょう',
      'pt': '🌧️ Chuva forte prevista em {destination} — planos internos?',
      'de': '🌧️ Starker Regen in {destination} erwartet — Indoor-Aktivitäten planen?',
    },
    'weather_heat': {
      'en': '🔥 {destination} hitting {temp}°C this week — stay hydrated!',
      'hi': '🔥 {destination} में इस हफ्ते {temp}°C — पानी पीते रहें!',
      'mr': '🔥 {destination} मध्ये या आठवड्यात {temp}°C — पाणी प्या!',
      'es': '🔥 ¡{destination} alcanzará {temp}°C esta semana — hidrátate!',
      'fr': '🔥 {destination} atteindra {temp}°C cette semaine — hydratez-vous !',
      'ja': '🔥 {destination}は今週{temp}°C — 水分補給を忘れずに！',
      'pt': '🔥 {destination} chegará a {temp}°C — mantenha-se hidratado!',
      'de': '🔥 {destination} erreicht {temp}°C — viel trinken!',
    },
    'weather_cold': {
      'en': '❄️ It\'s going to be cold in {destination} — pack warm layers',
      'hi': '❄️ {destination} में ठंड होगी — गर्म कपड़े पैक करें',
      'mr': '❄️ {destination} मध्ये थंडी असेल — उबदार कपडे पॅक करा',
      'es': '❄️ Hará frío en {destination} — lleva ropa de abrigo',
      'fr': '❄️ Il fera froid à {destination} — emportez des couches chaudes',
      'ja': '❄️ {destination}は寒くなります — 暖かい服を準備しましょう',
      'pt': '❄️ Vai fazer frio em {destination} — leve agasalhos',
      'de': '❄️ In {destination} wird es kalt — warme Kleidung einpacken',
    },
    'weather_perfect': {
      'en': '☀️ Weather in {destination} looks perfect for your trip!',
      'hi': '☀️ {destination} का मौसम आपकी ट्रिप के लिए बिल्कुल परफेक्ट!',
      'mr': '☀️ {destination} चे हवामान तुमच्या ट्रिपसाठी एकदम परफेक्ट!',
      'es': '☀️ ¡El clima en {destination} se ve perfecto para tu viaje!',
      'fr': '☀️ La météo à {destination} s\'annonce parfaite pour votre voyage !',
      'ja': '☀️ {destination}の天気は旅行にぴったり！',
      'pt': '☀️ O clima em {destination} está perfeito para sua viagem!',
      'de': '☀️ Das Wetter in {destination} sieht perfekt aus für deine Reise!',
    },

    // ── Engagement nudges ───────────────────────────────────────────
    'trip_approaching_3d': {
      'en': 'Your {destination} trip starts in 3 days ✈️',
      'hi': 'आपकी {destination} ट्रिप 3 दिनों में शुरू ✈️',
      'mr': 'तुमची {destination} ट्रिप 3 दिवसांत सुरू ✈️',
      'es': '¡Tu viaje a {destination} comienza en 3 días ✈️',
      'fr': 'Votre voyage à {destination} commence dans 3 jours ✈️',
      'ja': '{destination}旅行まであと3日 ✈️',
      'pt': 'Sua viagem para {destination} começa em 3 dias ✈️',
      'de': 'Deine {destination}-Reise startet in 3 Tagen ✈️',
    },
    'trip_going_dead': {
      'en': '{trip_name} is getting quiet 👀 Add something!',
      'hi': '{trip_name} शांत हो रही है 👀 कुछ ऐड करो!',
      'mr': '{trip_name} शांत होतेय 👀 काहीतरी ऍड करा!',
      'es': '¡{trip_name} se está quedando en silencio 👀 Añade algo!',
      'fr': '{trip_name} se calme 👀 Ajoutez quelque chose !',
      'ja': '{trip_name}が静かになってきた 👀 何か追加しよう！',
      'pt': '{trip_name} está ficando silencioso 👀 Adicione algo!',
      'de': '{trip_name} wird ruhig 👀 Füge etwas hinzu!',
    },
    'trip_no_members': {
      'en': 'Your {destination} trip needs crew! Share the invite',
      'hi': 'आपकी {destination} ट्रिप को साथी चाहिए! इनवाइट शेयर करें',
      'mr': 'तुमच्या {destination} ट्रिपला साथी हवेत! इन्व्हाइट शेअर करा',
      'es': '¡Tu viaje a {destination} necesita compañía! Comparte la invitación',
      'fr': 'Votre voyage à {destination} a besoin de monde ! Partagez l\'invitation',
      'ja': '{destination}旅行に仲間が必要！招待をシェアしよう',
      'pt': 'Sua viagem para {destination} precisa de companhia! Compartilhe o convite',
      'de': 'Deine {destination}-Reise braucht Begleitung! Teile die Einladung',
    },

    // ── Memory anniversaries ────────────────────────────────────────
    'memory_1y': {
      'en': '🌊 1 year ago you were in {destination} — want to go again?',
      'hi': '🌊 1 साल पहले आप {destination} में थे — फिर चलें?',
      'mr': '🌊 1 वर्षापूर्वी तुम्ही {destination} ला गेला होतात — परत जायचं?',
      'es': '🌊 Hace 1 año estabas en {destination} — ¿quieres volver?',
      'fr': '🌊 Il y a 1 an vous étiez à {destination} — on repart ?',
      'ja': '🌊 1年前、あなたは{destination}にいました — また行きたい？',
      'pt': '🌊 Há 1 ano você estava em {destination} — quer voltar?',
      'de': '🌊 Vor 1 Jahr warst du in {destination} — nochmal hin?',
    },
    'memory_6m': {
      'en': 'Half a year since {destination}... time for another adventure?',
      'hi': '{destination} से आधा साल हो गया... नई एडवेंचर का टाइम?',
      'mr': '{destination} पासून अर्धे वर्ष... नवीन साहसाची वेळ?',
      'es': 'Medio año desde {destination}... ¿hora de otra aventura?',
      'fr': 'Six mois depuis {destination}... une nouvelle aventure ?',
      'ja': '{destination}から半年...新たな冒険の時間？',
      'pt': 'Meio ano desde {destination}... hora de outra aventura?',
      'de': 'Ein halbes Jahr seit {destination}... Zeit für ein neues Abenteuer?',
    },
    'first_trip_anniversary': {
      'en': '🎂 Your very first WanderWith trip was 1 year ago today!',
      'hi': '🎂 आपकी पहली WanderWith ट्रिप आज 1 साल पहले थी!',
      'mr': '🎂 तुमची पहिली WanderWith ट्रिप आज 1 वर्षापूर्वी होती!',
      'es': '🎂 ¡Tu primer viaje con WanderWith fue hace 1 año!',
      'fr': '🎂 Votre tout premier voyage WanderWith c\'était il y a 1 an !',
      'ja': '🎂 あなたの最初のWanderWith旅行はちょうど1年前！',
      'pt': '🎂 Sua primeira viagem WanderWith foi há 1 ano!',
      'de': '🎂 Deine allererste WanderWith-Reise war vor genau 1 Jahr!',
    },

    // ── Admin / system ──────────────────────────────────────────────
    'admin_promoted': {
      'en': 'You\'re now an Admin in {trip_name}! 🎉',
      'hi': 'आप {trip_name} में अब Admin हैं! 🎉',
      'mr': 'तुम्ही आता {trip_name} मध्ये Admin आहात! 🎉',
      'es': '¡Ahora eres Admin en {trip_name}! 🎉',
      'fr': 'Vous êtes maintenant Admin de {trip_name} ! 🎉',
      'ja': '{trip_name}のAdminになりました！🎉',
      'pt': 'Agora você é Admin em {trip_name}! 🎉',
      'de': 'Du bist jetzt Admin in {trip_name}! 🎉',
    },
    'removed_from_trip': {
      'en': 'You have been removed from {trip_name}',
      'hi': 'आपको {trip_name} से हटा दिया गया है',
      'mr': 'तुम्हाला {trip_name} मधून काढले गेले आहे',
      'es': 'Has sido eliminado de {trip_name}',
      'fr': 'Vous avez été retiré de {trip_name}',
      'ja': '{trip_name}から削除されました',
      'pt': 'Você foi removido de {trip_name}',
      'de': 'Du wurdest aus {trip_name} entfernt',
    },
  };
}
