import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/trip.dart';
import '../config/app_env.dart';

class GeminiService {
  // ⚠️ In production, use Supabase Edge Functions to hide this key!
  String get _apiKey => AppEnv.geminiApiKey;

  Future<String> getTripSummary({
    required Trip trip,
    required List<Map<String, dynamic>> polls,
    required List<Map<String, dynamic>> recentMessages, // Last 10 messages
  }) async {
    
    // 1. Construct the context payload
    final tripContext = {
      'name': trip.name,
      'location': trip.location,
      'dates': trip.isDateDecided 
          ? "${trip.startDate?.toIso8601String()} to ${trip.endDate?.toIso8601String()}" 
          : "Undecided",
      'budget_currency': trip.budgetCurrency,
      'budget_metadata': trip.metadata?['budgetOptions'],
      'is_fixed_budget': trip.metadata?['isFixedBudget'] ?? false,
      'member_count': trip.memberIds.length,
      'polls_summary': polls.map((p) => {
        'question': p['question'],
        'open': true // simplified
      }).toList(),
      'recent_chat': recentMessages.map((m) => "${m['sender_name']}: ${m['text']}").toList()
    };

    // 2. Build the Prompt
    final prompt = """
You are an AI travel assistant for the app 'WanderWith'.
Analyze this trip data and provide a concise summary.

TRIP DATA:
${jsonEncode(tripContext)}

OUTPUT FORMAT:
Provide a response in this EXACT Markdown format:

**📌 Trip Status**
* [One line summary of location/dates]
* [One line on budget status]

**✅ Decided**
* [List solidified items]

**⚠️ Pending / Undecided**
* [List items needing attention based on polls/chat]

**👉 Suggested Next Step**
[One clear actionable step for the admin]

Keep it friendly but professional.
""";

    // 3. Call Gemini API
    try {
      final models = [
        'gemini-3-flash-preview',
        'gemini-2.5-flash',
        'gemini-1.5-flash-latest',
        'gemini-1.5-flash',
      ];

      for (final model in models) {
        final uri = Uri.https(
          'generativelanguage.googleapis.com',
          '/v1/models/$model:generateContent',
          {'key': _apiKey}
        );

        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "contents": [{
              "parts": [{ "text": prompt }]
            }]
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text = data['candidates']?[0]['content']?['parts']?[0]['text'];
          if (text == null || text.trim().isEmpty) {
            return "AI could not generate a summary at this time.";
          }
          return _stripMarkdown(text);
        }

        // If model not found/unsupported, try next one
        if (response.statusCode == 404) {
          continue;
        }

        throw Exception("AI Assistant error ${response.statusCode}: ${response.body}");
      }

      throw Exception("No available Gemini model found for this API key.");
    } catch (e) {
      if (e.toString().toLowerCase().contains('socketexception') || 
          e.toString().toLowerCase().contains('connection failed')) {
        throw Exception("You are offline. Please check your internet connection.");
      }
      throw Exception("Failed to reach AI Assistant. $e");
    }
  }

  Future<Map<String, dynamic>> generateTripPlan(Trip trip) async {
    // ⚠️ Updated Model Name to the stable 2.5 Flash from your list
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey');

    // Calculate explicit duration
    int durationDays = 3; // Default
    if (trip.startDate != null && trip.endDate != null) {
      durationDays = trip.endDate!.difference(trip.startDate!).inDays + 1;
    } else {
      durationDays = trip.metadata?['days'] ?? 3;
    }

    final prompt = """
You are a backend travel planning engine.
You do NOT check availability. You do NOT browse the live web.
Your ONLY job is to accept trip parameters and return a structured JSON itinerary.
The plan must be realistic, grouping locations geographically to minimize travel time.
Limit to 4-5 high-quality stops per day.

CRITICAL: You MUST generate EXACTLY $durationDays days of itinerary. No more, no less.
Each day's activities should be distinct and optimized for a $durationDays-day trip.

Make the plan purely based on the **Best Experience** for the location and duration.
Ignore any budget constraints. Create the best possible itinerary regardless of cost.
Admins can adjust the plan later if needed.

INPUT DATA:
Destination: ${trip.location}
Total Days: $durationDays
Dates: ${trip.startDate?.toIso8601String() ?? 'Day 1'} to ${trip.endDate?.toIso8601String() ?? 'Day $durationDays'}
Vibe: ${trip.metadata?['vibe'] ?? 'Balanced'}

OUTPUT FORMAT (STRICT JSON ONLY, NO MARKDOWN, NO COMMENTS):
{
  "day_plans": [
    {
      "day_number": 1,
      "date": "${trip.startDate?.toIso8601String().substring(0, 10) ?? 'YYYY-MM-DD'}",
      "summary": "Historical tour of old city",
      "activities": [
        {
          "name": "Shreemant Dagdusheth Halwai Ganpati Mandir",
          "type": "Temple",
          "query_name": "Shreemant Dagdusheth Halwai Ganpati Mandir ${trip.location}",
          "start_time": "09:00",
          "duration_hours": 1.5,
          "ai_insight": "A deeply spiritual experience; best visited during the morning Aarti. Observe the intricate gold work on the idol."
        }
      ]
    }
  ]
}
""";

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ],
           "generationConfig": {
            "response_mime_type": "application/json"
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] == null || data['candidates'].isEmpty) {
             throw Exception('Gemini returned no candidates.');
        }
        final contentText = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Clean up markdown code blocks if present format
        final cleanJson = contentText.replaceAll('```json', '').replaceAll('```', '').trim();
        return jsonDecode(cleanJson);
      } else {
        throw Exception('Gemini API Error: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to generate plan: $e');
    }
  }

  String _stripMarkdown(String input) {
    return input
        .replaceAll('**', '')
        .replaceAll('__', '')
        .replaceAll('## ', '')
        .replaceAll('# ', '')
        .replaceAll('* ', '')
        .trim();
  }

  // ---------------------------------------------------------------------------
  // NEW: Advanced Chat with Context
  // ---------------------------------------------------------------------------
  Future<String> getChatResponse({
    required String userMessage,
    required Trip trip,
    required List<Map<String, String>> history, // [{'role': 'user', 'text': '...'}, ...]
    String? planContext, // JSON string of the current itinerary
  }) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey');

    // 1. Build System Context
    final systemInstruction = """
You are WanderWith, a friendly travel buddy chatting inside a group trip chat. You're like that one friend who's been everywhere and always has the best tips.

Trip info you know:
- Going to: ${trip.location}
- Trip: ${trip.name}
- Dates: ${trip.startDate?.toIso8601String() ?? 'TBD'} to ${trip.endDate?.toIso8601String() ?? 'TBD'}
- Group size: ${trip.memberIds.length} people
- Currency: ${trip.budgetCurrency}
- Current plan: ${planContext ?? 'Nothing planned yet'}

How you reply:
- Talk like a real person texting in a group chat. Short, casual, helpful.
- NEVER use markdown formatting. No asterisks, no bold, no bullet points, no numbered lists, no headers.
- Keep replies brief — 2 to 4 sentences max unless they ask for detailed info.
- Use natural line breaks between thoughts, not bullet points.
- Be specific with place names and rough prices.
- If budget is tight, suggest affordable options only.
- Skip the formalities — no "Certainly!" or "Great question!" or "Here are some suggestions:".
- Sound like you're texting a friend, not writing a travel blog.
- You can use casual expressions and emojis sparingly.
- If someone asks for directions, just say the place name — they can search it.
""";

    // 2. Format History for Gemini API
    // API expects: contents: [{role: "user", parts: [{text: "..."}]}, {role: "model", ...}]
    List<Map<String, dynamic>> contents = [];
    
    // Inject system instruction as the first turn (or system instruction if supported, but turn 1 is safer for simple API)
    // Actually, gemini-1.5/2.5 supports 'systemInstruction' field, but let's put it in the first user prompt to be safe across versions
    // keeping it simple.
    
    // Add History
    for (var msg in history) {
      contents.add({
        "role": msg['role'] == 'user' ? "user" : "model",
        "parts": [{"text": msg['text']}]
      });
    }

    // Add Current Message with Context injected invisibly if it's the start
    String finalUserText = userMessage;
    if (history.isEmpty) {
      finalUserText = "$systemInstruction\n\nUSER QUESTION: $userMessage";
    }

    contents.add({
      "role": "user",
      "parts": [{"text": finalUserText}]
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": contents,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]['content']?['parts']?[0]['text'];
        return text ?? "I'm having trouble thinking right now. Try again.";
      } else {
        return "Error connecting to Travel Guide: ${response.statusCode}";
      }
    } catch (e) {
      return "Network error: $e";
    }
  }

  Future<List<Map<String, String>>> getAIPlaceSuggestions({
    required Trip trip,
    required int dayNumber,
    required List<String> existingActivities,
  }) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey');

    final prompt = """
You are a travel expert matching the vibe of a specific trip.
Based on the trip details and existing plan for Day $dayNumber, suggest 3-5 HIGH-QUALITY additional places the user might like to add.

TRIP CONTEXT:
Location: ${trip.location}
Vibe: ${trip.metadata?['vibe'] ?? 'Balanced'}
Target Day: Day $dayNumber
Current Activities for this day: ${existingActivities.join(', ')}

OUTPUT FORMAT (STRICT JSON LIST ONLY, NO MARKDOWN):
[
  {"name": "Place Name", "reason": "Short 1-sentence reason why it fits this day"},
  ...
]
""";

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{"parts": [{"text": prompt}]}],
          "generationConfig": {"response_mime_type": "application/json"}
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final contentText = data['candidates'][0]['content']['parts'][0]['text'];
        final List<dynamic> suggestions = jsonDecode(contentText);
        return suggestions.map((s) => {
          'name': s['name'].toString(),
          'reason': s['reason'].toString(),
        }).toList();
      }
    } catch (e) {
    }
    return [];
  }

  Future<String> generateImageCaption(String imageUrl, String destination) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey');

    final prompt = "You are a professional travel blogger. Looking at this photo from a trip to $destination, write a short, emotional, and engaging one-sentence caption (like an Instagram caption) with 1-2 relevant emojis. Return ONLY the caption text.";

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt},
                {"inline_data": {"mime_type": "image/jpeg", "data": base64Encode(await http.readBytes(Uri.parse(imageUrl)))}}
              ]
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]['content']?['parts']?[0]['text'];
        return text?.trim() ?? "Memories in $destination ✨";
      }
    } catch (e) {
      print('AI Caption Error: $e');
    }
    return "Great times in $destination! 📸";
  }

  /// Enrich destination with intelligence data (weather, visa, currency, etc.)
  Future<Map<String, dynamic>?> enrichDestination(String location) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey');

    final prompt = """
For the travel destination: "$location"

Return a JSON object with accurate, up-to-date information:
{
  "country_code": "ISO 3166-1 alpha-2 code (e.g., 'JP' for Japan)",
  "best_time_to_visit": "month range (e.g., 'March – May')",
  "best_time_weather_emoji": "single weather emoji",
  "crowd_level": "Low or Moderate or High (for current/typical season)",
  "avg_temp_range": "temperature range with unit (e.g., '24–30°C')",
  "visa_required": "Yes or No or On Arrival or E-Visa (from most common nationalities perspective)",
  "currency_code": "ISO 4217 currency code (e.g., 'JPY')",
  "currency_name": "full currency name (e.g., 'Japanese Yen')",
  "timezone": "GMT offset (e.g., 'GMT+9')",
  "language": "primary language (e.g., 'Japanese')",
  "emergency_number": "local emergency number (e.g., '110')"
}

IMPORTANT: Return ONLY the JSON object. No markdown, no explanation.
""";

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ],
          "generationConfig": {
            "response_mime_type": "application/json"
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]['content']?['parts']?[0]['text'];
        if (text != null) {
          final cleanJson = text.replaceAll('```json', '').replaceAll('```', '').trim();
          return jsonDecode(cleanJson) as Map<String, dynamic>;
        }
      }
    } catch (e) {
      print('AI Destination Enrichment Error: $e');
    }
    return null;
  }

  /// Get international travel info (visa, embassy, emergency) for a user traveling abroad
  Future<Map<String, dynamic>?> getInternationalTravelInfo(String userCountry, String destination) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey');

    final prompt = """
A traveler from "$userCountry" is visiting "$destination".

Provide accurate international travel information as JSON:
{
  "visa_required": "Yes or No or On Arrival or E-Visa",
  "visa_type": "type of visa needed (e.g., Tourist Visa, Visa on Arrival)",
  "stay_duration": "maximum allowed stay (e.g., 30 Days, 90 Days)",
  "processing_time": "typical processing time (e.g., 3-7 business days)",
  "visa_apply_url": "official government visa application URL if applicable, or null",
  "visa_fee_estimate": "approximate visa fee in USD (e.g., '\$40' or 'Free' or '\$25-\$50')",
  "visa_recommended_apply_date": "how many days before travel to apply (e.g., '30 days before departure')",
  "entry_requirements": "COVID/vaccine/health requirements if any, or 'None currently'",
  "embassy_name": "name of $userCountry's embassy/consulate in the destination country",
  "embassy_address": "full address of the embassy",
  "embassy_phone": "embassy phone number with country code",
  "embassy_emergency_number": "24/7 emergency helpline for citizens abroad",
  "embassy_email": "embassy email address",
  "local_emergency_number": "local general emergency number (e.g., 112)",
  "local_police_number": "local police number",
  "local_medical_number": "local medical/ambulance number",
  "plug_type": "power plug type used at destination (e.g., Type C / Type F, 230V 50Hz). Mention if traveler from $userCountry needs an adapter.",
  "tipping_customs": "brief tipping customs and norms (e.g., 10-15% at restaurants, not expected at cafés)",
  "useful_phrases": "5-8 essential phrases in local language with pronunciation (e.g., Hello = Bonjour (bon-ZHOOR), Thank you = Merci (mehr-SEE))",
  "sim_info": "advice on getting local SIM card or connectivity (e.g., buy at airport, eSIM recommended, free WiFi availability)",
  "passport_reminder": "passport validity requirement (e.g., Must be valid for 6+ months from date of entry)",
  "travel_insurance_note": "whether travel insurance is recommended or required, and brief advice",
  "driving_side": "Left or Right"
}

IMPORTANT: Return ONLY the JSON object. No markdown, no explanation.
Use null for any field where information is unavailable.
""";

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ],
          "generationConfig": {
            "response_mime_type": "application/json"
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]['content']?['parts']?[0]['text'];
        if (text != null) {
          final cleanJson = text.replaceAll('```json', '').replaceAll('```', '').trim();
          return jsonDecode(cleanJson) as Map<String, dynamic>;
        }
      }
    } catch (e) {
      print('AI International Info Error: $e');
    }
    return null;
  }

  /// Get AI-generated domestic travel intelligence for a destination within the user's own country
  Future<Map<String, dynamic>?> getDomesticTravelInfo(String destination) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey');

    final prompt = """
For domestic travel to "$destination", provide practical travel intelligence as JSON:
{
  "local_transport_tips": "brief guide to getting around — metro, buses, auto-rickshaws, cabs, ride-sharing apps, and any city-specific transport tips",
  "sim_connectivity_info": "mobile network coverage info, recommended carriers, WiFi availability, and any connectivity tips",
  "safety_tips": "destination-specific safety advice — areas to avoid, common scams, health precautions, and general travel safety tips",
  "local_customs": "local customs, etiquette, dress code recommendations, cultural norms, and any dos/don'ts travelers should know",
  "local_food_recommendations": "5-8 must-try local dishes or street food specialties with brief descriptions"
}

IMPORTANT: Return ONLY the JSON object. No markdown, no explanation.
Keep each field to 2-4 concise sentences. Be specific to the destination, not generic.
""";

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ],
          "generationConfig": {
            "response_mime_type": "application/json"
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]['content']?['parts']?[0]['text'];
        if (text != null) {
          final cleanJson = text.replaceAll('```json', '').replaceAll('```', '').trim();
          return jsonDecode(cleanJson) as Map<String, dynamic>;
        }
      }
    } catch (e) {
      print('AI Domestic Info Error: $e');
    }
    return null;
  }

  /// Get AI-generated insights for a specific place
  Future<Map<String, dynamic>?> getPlaceInsights(String placeName, String? tripLocation, {String? placeType}) async {
    final locationContext = tripLocation != null ? ' in "$tripLocation"' : '';
    final typeContext = placeType != null ? '\nPlace type: $placeType.' : '';
    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': '''For the place/attraction: "$placeName"$locationContext$typeContext

For natural attractions (beaches, parks, hiking trails, lakes, waterfalls), assume:
- Entry is typically free unless stated otherwise
- No ticket required unless it is a national park or protected area
- Estimate crowd based on rating and popularity
If specific data is unavailable, make reasonable travel-expert estimates rather than saying "unknown".

Provide a JSON object with the following fields:
{
  "best_time_to_visit": "morning/afternoon/evening + brief reason",
  "crowd_level": "Low|Moderate|High",
  "peak_hours": "e.g., 10 AM – 2 PM",
  "avg_visit_duration": "e.g., 1.5 - 2 hours",
  "ticket_required": true/false,
  "ticket_price_estimate": "price range in local currency or 'Free'",
  "online_booking_recommended": true/false,
  "booking_url": "official booking URL if available, otherwise null",
  "onsite_booking_available": true/false,
  "avg_waiting_time": "e.g., 15-30 min on weekends",
  "insider_tips": ["tip1", "tip2", "tip3"],
  "is_worth_visiting": "brief 1-2 sentence opinion",
  "family_friendly": true/false,
  "budget_friendly": true/false,
  "safety_rating": "Very Safe|Safe|Exercise Caution",
  "parking_available": true/false,
  "nearby_restrooms": true/false,
  "photography_allowed": true/false,
  "wheelchair_accessible": true/false,
  "estimated_cost_per_person": "e.g., ₹500-800 or Free",
  "recommended_duration_hours": 2.5,
  "local_tips": "cultural etiquette, dress code, or local customs relevant to this place"
}

Be accurate with real-world data. If unsure, provide best estimates.'''
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 2048,
            'response_mime_type': 'application/json',
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]['content']?['parts']?[0]['text'];
        if (text != null) {
          final cleanJson = text.replaceAll('```json', '').replaceAll('```', '').trim();
          try {
            return jsonDecode(cleanJson) as Map<String, dynamic>;
          } catch (parseError) {
            // If JSON is still truncated, try to salvage partial data
            print('AI Place Insights JSON parse error: $parseError');
            // Attempt to fix common truncation: add closing braces/brackets
            String fixedJson = cleanJson;
            // Count unclosed braces and brackets
            int openBraces = '{'.allMatches(fixedJson).length - '}'.allMatches(fixedJson).length;
            int openBrackets = '['.allMatches(fixedJson).length - ']'.allMatches(fixedJson).length;
            // Remove trailing incomplete key-value (after last comma)
            final lastComma = fixedJson.lastIndexOf(',');
            if (lastComma > 0 && openBraces > 0) {
              fixedJson = fixedJson.substring(0, lastComma);
            }
            // Re-count after trim
            openBraces = '{'.allMatches(fixedJson).length - '}'.allMatches(fixedJson).length;
            openBrackets = '['.allMatches(fixedJson).length - ']'.allMatches(fixedJson).length;
            for (int i = 0; i < openBrackets; i++) fixedJson += ']';
            for (int i = 0; i < openBraces; i++) fixedJson += '}';
            try {
              return jsonDecode(fixedJson) as Map<String, dynamic>;
            } catch (_) {
              return null;
            }
          }
        }
      }
    } catch (e) {
      print('AI Place Insights Error: $e');
    }
    return null;
  }
}
