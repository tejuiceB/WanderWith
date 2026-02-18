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

    final prompt = """
You are a backend travel planning engine.
You do NOT check availability. You do NOT browse the live web.
Your ONLY job is to accept trip parameters and return a structured JSON itinerary.
The plan must be realistic, grouping locations geographically to minimize travel time.
Limit to 4-5 high-quality stops per day.

Make the plan purely based on the **Best Experience** for the location and duration.
Ignore any budget constraints. Create the best possible itinerary regardless of cost.
Admins can adjust the plan later if needed.

INPUT DATA:
Destination: ${trip.location}
Dates: ${trip.startDate?.toIso8601String() ?? 'Day 1'} to ${trip.endDate?.toIso8601String() ?? 'Day ${trip.metadata?['days'] ?? 3}'}
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
You are a highly experienced, knowledgeable, and financially savvy Personal Travel Guide.
Your goal is to help the user with their trip to **${trip.location}**.

CONTEXT:
- Trip Name: ${trip.name}
- Dates: ${trip.startDate?.toIso8601String() ?? 'TBD'} to ${trip.endDate?.toIso8601String() ?? 'TBD'}
- Member Count: ${trip.memberIds.length}
- Currency: ${trip.budgetCurrency}
- Current Itinerary: ${planContext ?? 'No plan generated yet.'}

GUIDELINES:
1. **Strict Budget Adherence**: If the user mentions a specific budget (e.g., "I have 4 euros"), you MUST suggest options strictly within that limit (supermarkets, street food, free entry). Do NOT suggest expensive places if budget is tight.
2. **Be Specific**: Don't just say "there are restaurants". Say "Try 'Cafe X' for brunch or 'Place Y' for dinner."
3. **Pricing Estimates**: Always give price ranges based on local averages. (e.g., "Taxi from Airport: \$20-25").
4. **Directions**: When suggesting a place, provide a simple Google Maps search link in Markdown: `[Get Directions](https://www.google.com/maps/search/?api=1&query=PLACE_NAME_ENCODED)`.
5. **Tone**: Professional, friendly, and practical.

If the user asks about something not in the context, assume they mean near the city center or their current itinerary stops.
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
}
