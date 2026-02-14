import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Represents a single message in the chat conversation.
class ChatMessage {
  final String role; // 'user', 'assistant', or 'system'
  final String content;
  final DateTime timestamp;

  ChatMessage({required this.role, required this.content, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  Map<String, String> toJson() => {'role': role, 'content': content};
}

/// Service for text-based chat with the Ollama jayasimma/healthcare model.
class ChatService {
  static const String _systemPrompt =
      '''You are a specialized Dermatology and Skincare AI Assistant powered by SkinTermo AI. 
Your expertise includes skin condition analysis, personalized skincare routines, and evidence-based skin treatments.

Core Responsibilities:
1. Skincare Recommendations: Suggest active ingredients based on skin type and concerns (e.g., Niacinamide for inflammation, Salicylic acid for acne, Retinoids for aging, Ceramides for barrier repair).
2. Treatment Guidance: Explain common dermatological treatments (topical, oral, or procedural) for conditions like acne, eczema, psoriasis, and fungal infections.
3. Ingredient Education: Explain how specific ingredients work and potential side effects or interactions (e.g., sun sensitivity with AHAs/BHAs).
4. Routine Building: Help users construct AM/PM routines involving Cleansing, Treatment, Moisturizing, and Sun Protection.

Safety Guidelines:
- Always clarify that you are an AI, not a doctor.
- For severe cases (bleeding, rapid growth, intense pain), insist on immediate professional consultation.
- Recommend patch testing for new products.
- Emphasize the importance of SPF when using active treatments.

Tone: Professional, clinical yet empathetic, and highly informative.''';

  /// Send a chat message and get a response from the Ollama model.
  /// Takes the full conversation history for context-aware responses.
  static Future<String> sendMessage(
    List<ChatMessage> conversationHistory,
  ) async {
    try {
      final host = await ApiConfig.getEffectiveHost();
      final model = await ApiConfig.getModel();
      final url = '$host/api/chat';

      // Build messages array with system prompt
      final messages = <Map<String, String>>[
        {'role': 'system', 'content': _systemPrompt},
        ...conversationHistory.map((m) => m.toJson()),
      ];

      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': model,
              'messages': messages,
              'stream': false,
              'options': {'temperature': 0.4, 'num_predict': 1024},
            }),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final message = responseBody['message'];
        if (message != null && message['content'] != null) {
          return message['content'].toString().trim();
        }
        return 'I could not generate a response. Please try again.';
      } else {
        return 'Server error (${response.statusCode}). Please check that Ollama is running and the jayasimma/gennai model is installed.';
      }
    } on SocketException {
      return 'Cannot connect to the Ollama server. Please make sure:\n\n'
          '1. Ollama is running (ollama serve)\n'
          '2. The model is installed (ollama pull jayasimma/gennai)\n'
          '3. Check the server URL in Settings';
    } on http.ClientException {
      return 'Connection failed. Please check your network and Ollama server status.';
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return 'Request timed out. The model may be loading. Please try again in a moment.';
      }
      return 'An error occurred: ${e.toString()}';
    }
  }

  /// Test if the chat endpoint is reachable.
  static Future<bool> testChatEndpoint() async {
    try {
      final host = await ApiConfig.getEffectiveHost();
      final response = await http
          .get(Uri.parse(host))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
