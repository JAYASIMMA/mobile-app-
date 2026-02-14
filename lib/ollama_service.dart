import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class OllamaService {
  /// Sends an image to the Ollama API and returns the prediction result.
  /// The image is encoded as base64 and sent to the jayasimma/healthcare model.
  static Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final url = await ApiConfig.getGenerateUrl();
      final model = await ApiConfig.getModel();

      final prompt = '''You are a dermatology AI assistant. Analyze this skin image carefully.
Provide your analysis in the following JSON format ONLY, with no extra text:
{
  "disease_name": "Name of the detected skin condition",
  "confidence": "High/Medium/Low",
  "severity": "Mild/Moderate/Severe",
  "description": "Brief description of the condition",
  "symptoms": ["symptom1", "symptom2"],
  "recommendations": ["recommendation1", "recommendation2"],
  "seek_medical_attention": true/false
}''';

      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': model,
              'prompt': prompt,
              'images': [base64Image],
              'stream': false,
              'options': {
                'temperature': 0.3,
                'num_predict': 1024,
              },
            }),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final rawResponse = responseBody['response'] ?? '';

        // Try to parse JSON from the response
        return _parseResponse(rawResponse);
      } else {
        return {
          'error': true,
          'disease_name': 'Server Error',
          'description':
              'Server returned status ${response.statusCode}. Please check your Ollama server.',
          'confidence': 'N/A',
          'severity': 'N/A',
          'symptoms': <String>[],
          'recommendations': ['Check if Ollama server is running', 'Verify the model is installed'],
          'seek_medical_attention': false,
        };
      }
    } on SocketException {
      return {
        'error': true,
        'disease_name': 'Connection Failed',
        'description':
            'Cannot reach the Ollama server. Make sure it is running and the URL is correct.',
        'confidence': 'N/A',
        'severity': 'N/A',
        'symptoms': <String>[],
        'recommendations': [
          'Start Ollama server: ollama serve',
          'Pull the model: ollama pull jayasimma/healthcare',
          'Check server URL in Settings'
        ],
        'seek_medical_attention': false,
      };
    } catch (e) {
      return {
        'error': true,
        'disease_name': 'Analysis Error',
        'description': 'An unexpected error occurred: ${e.toString()}',
        'confidence': 'N/A',
        'severity': 'N/A',
        'symptoms': <String>[],
        'recommendations': ['Try again', 'Check your internet connection'],
        'seek_medical_attention': false,
      };
    }
  }

  /// Parse the raw string response from Ollama into structured data.
  static Map<String, dynamic> _parseResponse(String rawResponse) {
    try {
      // Try to find JSON in the response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(rawResponse);
      if (jsonMatch != null) {
        final parsed = jsonDecode(jsonMatch.group(0)!);
        return {
          'error': false,
          'disease_name': parsed['disease_name'] ?? 'Unknown',
          'confidence': parsed['confidence'] ?? 'N/A',
          'severity': parsed['severity'] ?? 'N/A',
          'description': parsed['description'] ?? 'No description available.',
          'symptoms': List<String>.from(parsed['symptoms'] ?? []),
          'recommendations': List<String>.from(parsed['recommendations'] ?? []),
          'seek_medical_attention': parsed['seek_medical_attention'] ?? false,
        };
      }
    } catch (_) {}

    // Fallback: return raw text as description
    return {
      'error': false,
      'disease_name': 'Analysis Complete',
      'confidence': 'N/A',
      'severity': 'N/A',
      'description': rawResponse.trim(),
      'symptoms': <String>[],
      'recommendations': ['Consult a dermatologist for proper diagnosis'],
      'seek_medical_attention': true,
    };
  }

  /// Test connectivity to the Ollama server.
  static Future<bool> testConnection() async {
    try {
      final host = await ApiConfig.getHost();
      final response = await http
          .get(Uri.parse(host))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
