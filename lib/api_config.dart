import 'package:shared_preferences/shared_preferences.dart';

enum InferenceMode { ollama, tflite }

class ApiConfig {
  static const String _hostKey = 'ollama_host';
  static const String _modelKey = 'ollama_model';
  static const String _inferenceModeKey = 'inference_mode';

  static const String defaultHost = 'http://localhost:11434';
  static const String defaultModel = 'jayasimma/healthcare';

  static Future<String> getHost() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_hostKey) ?? defaultHost;
  }

  static Future<String> getModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_modelKey) ?? defaultModel;
  }

  static Future<void> setHost(String host) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hostKey, host);
  }

  static Future<void> setModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelKey, model);
  }

  /// Returns the generate endpoint URL
  static Future<String> getGenerateUrl() async {
    final host = await getHost();
    return '$host/api/generate';
  }

  /// Get the current inference mode (Ollama or TFLite)
  static Future<InferenceMode> getInferenceMode() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString(_inferenceModeKey) ?? 'ollama';
    return mode == 'tflite' ? InferenceMode.tflite : InferenceMode.ollama;
  }

  /// Set the inference mode
  static Future<void> setInferenceMode(InferenceMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _inferenceModeKey, mode == InferenceMode.tflite ? 'tflite' : 'ollama');
  }
}
