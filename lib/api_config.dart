import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

enum InferenceMode { ollama, tflite }

class ApiConfig {
  static const String _hostKey = 'ollama_host';
  static const String _modelKey = 'ollama_model';
  static const String _inferenceModeKey = 'inference_mode';

  static const String defaultHost = 'http://localhost:11434';
  static const String defaultModel = 'jayasimma/gennai';

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

  /// Returns the effective host URL, automatically replacing localhost with
  /// 10.0.2.2 when running on an Android emulator.
  /// This is critical for Android emulator connectivity:
  ///   - Emulator's "localhost" points to the emulator itself
  ///   - "10.0.2.2" is the special alias for the host machine's loopback
  static Future<String> getEffectiveHost() async {
    final host = await getHost();

    // On Android, redirect localhost to the emulator host alias
    if (Platform.isAndroid) {
      return host
          .replaceAll('localhost', '10.0.2.2')
          .replaceAll('127.0.0.1', '10.0.2.2');
    }

    return host;
  }

  /// Returns the /api/generate endpoint URL (for image analysis)
  static Future<String> getGenerateUrl() async {
    final host = await getEffectiveHost();
    return '$host/api/generate';
  }

  /// Returns the /api/chat endpoint URL (for text chat)
  static Future<String> getChatUrl() async {
    final host = await getEffectiveHost();
    return '$host/api/chat';
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
      _inferenceModeKey,
      mode == InferenceMode.tflite ? 'tflite' : 'ollama',
    );
  }
}
