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

  String _stripMarkdown(String input) {
    return input
        .replaceAll('**', '')
        .replaceAll('__', '')
        .replaceAll('## ', '')
        .replaceAll('# ', '')
        .replaceAll('* ', '')
        .trim();
  }
}
