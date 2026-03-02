// supabase/functions/smart-notifications/index.ts
//
// Edge Function — Smart Notification Engine (cron: every 6 hours)
//
// Processes:
//   1. Scheduled notifications ready to send
//   2. Trip lifecycle reminders (7d, 3d, 1d before · start day · 1d, 3d, 7d after)
//   3. Weather alerts for upcoming trips
//   4. Festival alerts by country
//   5. Memory anniversaries (6 months, 1 year)
//
// Invoked by pg_cron or Supabase Scheduled Functions.
// Uses service_role key for full DB access.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const WEATHER_API_KEY = Deno.env.get("WEATHER_API_KEY") ?? "";

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

// ── Templates (matching notification_templates.dart keys) ───────
const TEMPLATES: Record<string, Record<string, string>> = {
  trip_starting_7d: {
    en: "🧳 Packing reminder: {destination} in 1 week!",
    hi: "🧳 पैकिंग रिमाइंडर: {destination} सिर्फ 1 हफ्ते में!",
    mr: "🧳 पॅकिंग रिमाइंडर: {destination} 1 आठवड्यात!",
    es: "🧳 ¡Recuerda empacar! {destination} en 1 semana",
    fr: "🧳 Rappel de valise : {destination} dans 1 semaine !",
    ja: "🧳 荷造りリマインダー：{destination}まであと1週間！",
    pt: "🧳 Lembrete: {destination} em 1 semana!",
    de: "🧳 Packen nicht vergessen: {destination} in 1 Woche!",
  },
  trip_starting_3d: {
    en: "🌤 Weather alert: {destination} will be {temp}° — pack accordingly",
    hi: "🌤 मौसम अलर्ट: {destination} में {temp}° रहेगा — सोच-समझकर पैक करें",
    es: "🌤 Alerta meteorológica: {destination} estará a {temp}° — prepárate",
    fr: "🌤 Alerte météo : {destination} fera {temp}° — préparez-vous",
    ja: "🌤 天気予報：{destination}は{temp}°になります — 準備しましょう",
  },
  trip_starting_1d: {
    en: "🚨 {destination} trip starts tomorrow! All set?",
    hi: "🚨 {destination} ट्रिप कल शुरू! सब तैयार?",
    es: "🚨 ¡Tu viaje a {destination} empieza mañana! ¿Todo listo?",
    fr: "🚨 Votre voyage à {destination} commence demain ! Tout est prêt ?",
    ja: "🚨 {destination}旅行は明日出発！準備はOK？",
  },
  trip_start_day: {
    en: "🎉 Your {destination} trip starts today! Have an amazing time",
    hi: "🎉 आपकी {destination} ट्रिप आज शुरू! शानदार समय बिताइए",
    es: "🎉 ¡Tu viaje a {destination} empieza hoy! Disfrútalo",
  },
  trip_ended_1d: {
    en: "📸 Relive your {destination} memories",
    hi: "📸 {destination} की यादें फिर से जीएं",
  },
  trip_ended_3d: {
    en: "✍️ Share your {destination} experience — create a highlight post",
    hi: "✍️ {destination} का अनुभव शेयर करें — हाइलाइट पोस्ट बनाएं",
  },
  trip_ended_7d: {
    en: "⭐ Rate your {destination} trip and help others",
    hi: "⭐ {destination} ट्रिप को रेट करें और दूसरों की मदद करें",
  },
  weather_rain: {
    en: "🌧️ Heavy rain expected during your {destination} trip — plan indoor activities?",
    hi: "🌧️ {destination} ट्रिप में भारी बारिश — इनडोर प्लान बनाएं?",
  },
  weather_heat: {
    en: "🔥 {destination} hitting {temp}°C this week — stay hydrated!",
    hi: "🔥 {destination} में इस हफ्ते {temp}°C — पानी पीते रहें!",
  },
  weather_cold: {
    en: "❄️ It's going to be cold in {destination} — pack warm layers",
    hi: "❄️ {destination} में ठंड होगी — गर्म कपड़े पैक करें",
  },
  weather_perfect: {
    en: "☀️ Weather in {destination} looks perfect for your trip!",
    hi: "☀️ {destination} का मौसम आपकी ट्रिप के लिए बिल्कुल परफेक्ट!",
  },
  memory_1y: {
    en: "🌊 1 year ago you were in {destination} — want to go again?",
    hi: "🌊 1 साल पहले आप {destination} में थे — फिर चलें?",
  },
  memory_6m: {
    en: "Half a year since {destination}... time for another adventure?",
    hi: "{destination} से आधा साल हो गया... नई एडवेंचर का टाइम?",
  },
};

// ── Festival database (matching festival_calendar.dart) ─────────
interface Festival {
  country: string;
  name: string;
  month: number;
  day: number;
  messages: Record<string, string>;
}

const FESTIVALS: Festival[] = [
  { country: "IN", name: "Diwali", month: 10, day: 25, messages: { en: "Diwali long weekend? Plan a getaway 🪔", hi: "दिवाली की छुट्टियां? कहीं घूमने चलें 🪔" } },
  { country: "IN", name: "Holi", month: 3, day: 14, messages: { en: "Holi is coming! Plan a colorful trip 🎨", hi: "होली आ रही है! रंगीन ट्रिप प्लान करें 🎨" } },
  { country: "US", name: "Thanksgiving", month: 11, day: 28, messages: { en: "Thanksgiving break = road trip time 🦃" } },
  { country: "US", name: "Spring Break", month: 3, day: 15, messages: { en: "Spring Break is near — start planning! 🌴" } },
  { country: "US", name: "Independence Day", month: 7, day: 4, messages: { en: "July 4th weekend trip? 🎆" } },
  { country: "US", name: "Memorial Day", month: 5, day: 27, messages: { en: "Memorial Day weekend getaway? 🇺🇸" } },
  { country: "JP", name: "Cherry Blossom", month: 3, day: 25, messages: { en: "Cherry blossom season! Plan a Japan trip 🌸", ja: "桜の季節！旅行を計画しよう 🌸" } },
  { country: "JP", name: "Golden Week", month: 4, day: 29, messages: { en: "Golden Week is coming! 🌟", ja: "ゴールデンウィーク目前！旅の計画を 🌟" } },
  { country: "JP", name: "Obon", month: 8, day: 13, messages: { en: "Obon holiday — perfect for a trip 🏮", ja: "お盆休み — 旅行にぴったり 🏮" } },
  { country: "GB", name: "May Bank Holiday", month: 5, day: 6, messages: { en: "Bank holiday coming up — quick getaway? 🇬🇧" } },
  { country: "GB", name: "August Bank Holiday", month: 8, day: 26, messages: { en: "August bank holiday — last summer trip? ☀️" } },
  { country: "FR", name: "Bastille Day", month: 7, day: 14, messages: { en: "Bastille Day — explore France! 🇫🇷", fr: "14 Juillet — partez en voyage ! 🇫🇷" } },
  { country: "BR", name: "Carnaval", month: 2, day: 25, messages: { en: "Carnaval is near — plan your Brazil trip 🎭", pt: "Carnaval chegando — planeje sua viagem 🎭" } },
  { country: "DE", name: "Oktoberfest", month: 9, day: 21, messages: { en: "Oktoberfest season — trip to Munich? 🍺", de: "Oktoberfest — ab nach München? 🍺" } },
  { country: "DE", name: "Christmas Markets", month: 11, day: 25, messages: { en: "Christmas market season in Germany! 🎄", de: "Weihnachtsmarkt-Zeit! 🎄" } },
  { country: "ES", name: "La Tomatina", month: 8, day: 28, messages: { en: "La Tomatina is coming — head to Spain! 🍅", es: "¡La Tomatina se acerca — viaja a España! 🍅" } },
];

// ── Country code heuristic from country name ────────────────────
function countryToCode(country: string | null): string {
  if (!country) return "";
  const map: Record<string, string> = {
    india: "IN", "united states": "US", usa: "US", japan: "JP",
    "united kingdom": "GB", uk: "GB", france: "FR", brazil: "BR",
    germany: "DE", spain: "ES", mexico: "MX", argentina: "AR",
    colombia: "CO", austria: "AT", australia: "AU", canada: "CA",
  };
  return map[country.toLowerCase()] ?? "";
}

// ── Language resolution ─────────────────────────────────────────
function resolveLang(preferredLang: string | null, country: string | null): string {
  if (preferredLang && preferredLang !== "auto") return preferredLang;
  const cc = countryToCode(country);
  const langMap: Record<string, string> = {
    IN: "en", JP: "ja", BR: "pt", DE: "de", FR: "fr", ES: "es", MX: "es",
  };
  return langMap[cc] ?? "en";
}

// ── Template resolver ───────────────────────────────────────────
function resolveTemplate(
  key: string,
  lang: string,
  vars: Record<string, string> = {}
): string {
  const langMap = TEMPLATES[key];
  if (!langMap) return key;
  let tpl = langMap[lang] ?? langMap["en"] ?? key;
  for (const [k, v] of Object.entries(vars)) {
    tpl = tpl.replaceAll(`{${k}}`, v);
  }
  return tpl;
}

// ── Title lookup ────────────────────────────────────────────────
function titleForType(type: string, lang: string): string {
  const titles: Record<string, Record<string, string>> = {
    trip_reminder: { en: "Trip Reminder", hi: "ट्रिप रिमाइंडर", es: "Recordatorio de viaje", fr: "Rappel de voyage", ja: "旅行リマインダー" },
    weather_alert: { en: "Weather Alert", hi: "मौसम अलर्ट", es: "Alerta meteorológica", fr: "Alerte météo", ja: "天気アラート" },
    festival_alert: { en: "Festival Alert", hi: "त्योहार अलर्ट", es: "Alerta de festival", fr: "Alerte festival", ja: "フェスティバルアラート" },
    travel_inspiration: { en: "Travel Inspiration ✨", hi: "ट्रैवल इंस्पिरेशन" },
    memory_anniversary: { en: "Memories 💛", hi: "यादें 💛" },
  };
  return titles[type]?.[lang] ?? titles[type]?.["en"] ?? "WanderWith";
}

// ── Anti-spam: check if already sent today ──────────────────────
async function isDuplicate(
  userId: string,
  subtype: string,
  tripId: string | null
): Promise<boolean> {
  const since = new Date();
  since.setHours(since.getHours() - 12);

  let query = supabase
    .from("notification_log")
    .select("id")
    .eq("user_id", userId)
    .eq("subtype", subtype)
    .gte("sent_at", since.toISOString())
    .limit(1);

  if (tripId) query = query.eq("trip_id", tripId);

  const { data } = await query;
  return (data?.length ?? 0) > 0;
}

// ── Log a sent notification ─────────────────────────────────────
async function logNotification(
  userId: string,
  notificationType: string,
  subtype: string,
  tripId: string | null
): Promise<void> {
  await supabase.from("notification_log").insert({
    user_id: userId,
    notification_type: notificationType,
    subtype,
    trip_id: tripId,
  });
}

// ── Insert into the real notifications table (instant send) ─────
async function sendNotification(
  userId: string,
  title: string,
  body: string,
  type: string,
  tripId: string | null
): Promise<void> {
  await supabase.from("notifications").insert({
    user_id: userId,
    title,
    body,
    type,
    trip_id: tripId,
    is_read: false,
  });
}

// ── Category enabled check ──────────────────────────────────────
function isCategoryEnabled(
  prefs: Record<string, unknown> | null,
  category: string
): boolean {
  if (!prefs) return true;
  return prefs[category] !== false;
}

// ═══════════════════════════════════════════════════════════════════
// Processors
// ═══════════════════════════════════════════════════════════════════

// 1. Process pending scheduled_notifications
async function processScheduled(): Promise<number> {
  const now = new Date().toISOString();
  const { data: pending } = await supabase
    .from("scheduled_notifications")
    .select("*")
    .eq("sent", false)
    .lte("scheduled_for", now)
    .limit(200);

  if (!pending?.length) return 0;

  let sent = 0;
  for (const n of pending) {
    try {
      await sendNotification(n.user_id, n.title, n.body, n.type, n.trip_id);
      await supabase
        .from("scheduled_notifications")
        .update({ sent: true, sent_at: now })
        .eq("id", n.id);
      sent++;
    } catch (e) {
      console.error(`Failed to send scheduled ${n.id}:`, e);
    }
  }
  return sent;
}

// 2. Trip lifecycle notifications
async function processTripLifecycle(): Promise<number> {
  let sent = 0;

  // ── Upcoming trips (7 days ahead) ─────────────────────────
  const { data: upcoming } = await supabase.rpc("get_upcoming_trip_users", {
    days_ahead: 7,
  });

  if (upcoming?.length) {
    for (const row of upcoming) {
      const lang = resolveLang(row.preferred_language, row.country);
      const prefs = row.notification_prefs as Record<string, unknown> | null;
      if (!isCategoryEnabled(prefs, "trip_reminders")) continue;

      const days = row.days_until;
      let templateKey: string | null = null;

      if (days === 7) templateKey = "trip_starting_7d";
      else if (days === 3) templateKey = "trip_starting_3d";
      else if (days === 1) templateKey = "trip_starting_1d";
      else if (days === 0) templateKey = "trip_start_day";

      if (!templateKey) continue;

      const dup = await isDuplicate(row.user_id, templateKey, row.trip_id);
      if (dup) continue;

      const vars: Record<string, string> = {
        destination: row.destination ?? "your trip",
        temp: "",  // filled by weather check for 3d
      };

      // For 3-day reminder, try to fetch weather
      if (days === 3 && WEATHER_API_KEY && row.destination) {
        try {
          const resp = await fetch(
            `https://api.weatherapi.com/v1/forecast.json?key=${WEATHER_API_KEY}&q=${encodeURIComponent(row.destination)}&days=3`
          );
          if (resp.ok) {
            const wx = await resp.json();
            const avgTemp = Math.round(wx.forecast?.forecastday?.[2]?.day?.avgtemp_c ?? 0);
            vars.temp = String(avgTemp);
          }
        } catch { /* weather fetch failed — use template without temp */ }
      }

      const body = resolveTemplate(templateKey, lang, vars);
      const title = titleForType("trip_reminder", lang);

      await sendNotification(row.user_id, title, body, "trip_reminder", row.trip_id);
      await logNotification(row.user_id, "engagement", templateKey, row.trip_id);
      sent++;
    }
  }

  // ── Recently ended trips ──────────────────────────────────
  const { data: ended } = await supabase.rpc("get_recently_ended_trips", {
    days_since: 7,
  });

  if (ended?.length) {
    for (const row of ended) {
      const lang = resolveLang(row.preferred_language, null);
      const prefs = row.notification_prefs as Record<string, unknown> | null;
      if (!isCategoryEnabled(prefs, "trip_reminders")) continue;

      const since = row.days_since_end;
      let templateKey: string | null = null;

      if (since === 1) templateKey = "trip_ended_1d";
      else if (since === 3) templateKey = "trip_ended_3d";
      else if (since === 7) templateKey = "trip_ended_7d";

      if (!templateKey) continue;

      const dup = await isDuplicate(row.user_id, templateKey, row.trip_id);
      if (dup) continue;

      const vars = { destination: row.destination ?? "your trip" };
      const body = resolveTemplate(templateKey, lang, vars);
      const title = titleForType("trip_reminder", lang);

      await sendNotification(row.user_id, title, body, "trip_reminder", row.trip_id);
      await logNotification(row.user_id, "engagement", templateKey, row.trip_id);
      sent++;
    }
  }

  return sent;
}

// 3. Weather alerts for trips starting in 1-3 days
async function processWeatherAlerts(): Promise<number> {
  if (!WEATHER_API_KEY) return 0;

  let sent = 0;
  const { data: upcoming } = await supabase.rpc("get_upcoming_trip_users", {
    days_ahead: 3,
  });

  if (!upcoming?.length) return 0;

  for (const row of upcoming) {
    if (!row.destination) continue;
    const prefs = row.notification_prefs as Record<string, unknown> | null;
    if (!isCategoryEnabled(prefs, "weather_alerts")) continue;

    const dup = await isDuplicate(row.user_id, "weather_alert_" + row.trip_id, row.trip_id);
    if (dup) continue;

    try {
      const resp = await fetch(
        `https://api.weatherapi.com/v1/forecast.json?key=${WEATHER_API_KEY}&q=${encodeURIComponent(row.destination)}&days=3`
      );
      if (!resp.ok) continue;

      const wx = await resp.json();
      const forecastDay = wx.forecast?.forecastday?.[0]?.day;
      if (!forecastDay) continue;

      const avgTemp = Math.round(forecastDay.avgtemp_c ?? 20);
      const maxWind = forecastDay.maxwind_kph ?? 0;
      const rain = forecastDay.daily_chance_of_rain ?? 0;
      const condition = forecastDay.condition?.text ?? "";

      let templateKey: string;
      if (rain > 60) templateKey = "weather_rain";
      else if (avgTemp > 35) templateKey = "weather_heat";
      else if (avgTemp < 5) templateKey = "weather_cold";
      else if (rain < 20 && avgTemp >= 15 && avgTemp <= 30 && maxWind < 30) templateKey = "weather_perfect";
      else continue; // not noteworthy

      const lang = resolveLang(row.preferred_language, row.country);
      const vars = {
        destination: row.destination,
        temp: String(avgTemp),
        condition,
      };

      const body = resolveTemplate(templateKey, lang, vars);
      const title = titleForType("weather_alert", lang);

      await sendNotification(row.user_id, title, body, "weather_alert", row.trip_id);
      await logNotification(row.user_id, "engagement", "weather_alert_" + row.trip_id, row.trip_id);
      sent++;
    } catch (e) {
      console.error(`Weather fetch failed for ${row.destination}:`, e);
    }
  }

  return sent;
}

// 4. Festival alerts
async function processFestivalAlerts(): Promise<number> {
  let sent = 0;
  const now = new Date();

  // Get all users with a country set
  const { data: users } = await supabase
    .from("profiles")
    .select("id, country, notification_prefs, preferred_notification_language")
    .not("country", "is", null)
    .limit(1000);

  if (!users?.length) return 0;

  for (const user of users) {
    const cc = countryToCode(user.country);
    if (!cc) continue;

    const prefs = user.notification_prefs as Record<string, unknown> | null;
    if (!isCategoryEnabled(prefs, "festival_alerts")) continue;

    // Check each festival for this country within 10 days
    for (const fest of FESTIVALS) {
      if (fest.country !== cc) continue;

      const festDate = new Date(now.getFullYear(), fest.month - 1, fest.day);
      const diff = Math.floor((festDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
      if (diff < 0 || diff > 10) continue;

      const subtype = `festival_${fest.name.toLowerCase().replace(/\s+/g, "_")}`;
      const dup = await isDuplicate(user.id, subtype, null);
      if (dup) continue;

      const lang = resolveLang(user.preferred_notification_language, user.country);
      const body = fest.messages[lang] ?? fest.messages["en"] ?? `${fest.name} is coming!`;
      const title = titleForType("festival_alert", lang);

      await sendNotification(user.id, title, body, "festival_alert", null);
      await logNotification(user.id, "engagement", subtype, null);
      sent++;
    }
  }

  return sent;
}

// 5. Memory anniversaries
async function processMemoryAnniversaries(): Promise<number> {
  let sent = 0;

  const { data: anniversaries } = await supabase.rpc("get_trip_anniversaries");
  if (!anniversaries?.length) return 0;

  // Fetch user prefs for each unique user
  const userIds = [...new Set(anniversaries.map((a: { user_id: string }) => a.user_id))];
  const { data: users } = await supabase
    .from("profiles")
    .select("id, notification_prefs, preferred_notification_language, country")
    .in("id", userIds);

  const userMap = new Map(users?.map((u: { id: string }) => [u.id, u]) ?? []);

  for (const ann of anniversaries) {
    const user = userMap.get(ann.user_id) as Record<string, unknown> | undefined;
    if (!user) continue;

    const prefs = user.notification_prefs as Record<string, unknown> | null;
    if (!isCategoryEnabled(prefs, "travel_inspiration")) continue;

    const subtype = `memory_${ann.anniversary_type}_${ann.trip_id}`;
    const dup = await isDuplicate(ann.user_id, subtype, ann.trip_id);
    if (dup) continue;

    const lang = resolveLang(user.preferred_notification_language as string, user.country as string);
    const templateKey = ann.anniversary_type === "1y" ? "memory_1y" : "memory_6m";
    const vars = { destination: ann.destination ?? "your trip" };
    const body = resolveTemplate(templateKey, lang, vars);
    const title = titleForType("memory_anniversary", lang);

    await sendNotification(ann.user_id, title, body, "memory_anniversary", ann.trip_id);
    await logNotification(ann.user_id, "marketing", subtype, ann.trip_id);
    sent++;
  }

  return sent;
}

// ═══════════════════════════════════════════════════════════════════
// Main handler
// ═══════════════════════════════════════════════════════════════════
Deno.serve(async (req) => {
  try {
    // Optional: verify Authorization header or cron secret
    const authHeader = req.headers.get("Authorization");
    const cronSecret = Deno.env.get("CRON_SECRET");
    if (cronSecret && authHeader !== `Bearer ${cronSecret}`) {
      // Allow service_role token too
      if (authHeader !== `Bearer ${SUPABASE_SERVICE_KEY}`) {
        return new Response(JSON.stringify({ error: "Unauthorized" }), {
          status: 401,
          headers: { "Content-Type": "application/json" },
        });
      }
    }

    console.log("[smart-notifications] Starting run at", new Date().toISOString());

    const [scheduled, lifecycle, weather, festivals, memories] = await Promise.all([
      processScheduled(),
      processTripLifecycle(),
      processWeatherAlerts(),
      processFestivalAlerts(),
      processMemoryAnniversaries(),
    ]);

    const summary = {
      timestamp: new Date().toISOString(),
      scheduled_processed: scheduled,
      lifecycle_sent: lifecycle,
      weather_sent: weather,
      festival_sent: festivals,
      memory_sent: memories,
      total: scheduled + lifecycle + weather + festivals + memories,
    };

    console.log("[smart-notifications] Complete:", JSON.stringify(summary));

    return new Response(JSON.stringify(summary), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("[smart-notifications] Fatal error:", e);
    return new Response(
      JSON.stringify({ error: (e as Error).message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
