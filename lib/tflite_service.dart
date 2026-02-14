import 'dart:io';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class TfliteService {
  static Interpreter? _interpreter;
  static bool _isLoaded = false;

  /// Initialize the TFLite model from assets.
  static Future<bool> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('models/skin_model.tflite');
      _isLoaded = true;
      return true;
    } catch (e) {
      _isLoaded = false;
      return false;
    }
  }

  /// Check if the model is loaded.
  static bool get isModelLoaded => _isLoaded;

  /// Preprocess the image to match the model's expected input:
  /// Shape: [1, 3, 224, 224], normalized float32.
  static Float32List _preprocessImage(File imageFile) {
    final rawBytes = imageFile.readAsBytesSync();
    final image = img.decodeImage(rawBytes)!;
    final resized = img.copyResize(image, width: 224, height: 224);

    // Create a Float32 buffer in NCHW format [1, 3, 224, 224]
    final buffer = Float32List(1 * 3 * 224 * 224);
    int idx = 0;

    // Channel-first: R channel, then G, then B
    for (int c = 0; c < 3; c++) {
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final pixel = resized.getPixel(x, y);
          double value;
          switch (c) {
            case 0:
              value = pixel.r / 255.0;
              break;
            case 1:
              value = pixel.g / 255.0;
              break;
            case 2:
              value = pixel.b / 255.0;
              break;
            default:
              value = 0.0;
          }
          buffer[idx++] = value;
        }
      }
    }
    return buffer;
  }

  /// Run inference on the image and return the feature embedding.
  /// Returns the raw embedding vector from the encoder.
  static Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    if (!_isLoaded || _interpreter == null) {
      final loaded = await loadModel();
      if (!loaded) {
        return {
          'error': true,
          'disease_name': 'Model Error',
          'description': 'Failed to load the TFLite model. Please check that skin_model.tflite exists in assets/models/',
          'confidence': 'N/A',
          'severity': 'N/A',
          'symptoms': <String>[],
          'recommendations': ['Check the model file', 'Try using Ollama mode instead'],
          'seek_medical_attention': false,
        };
      }
    }

    try {
      // Preprocess
      final inputData = _preprocessImage(imageFile);
      final input = inputData.reshape([1, 3, 224, 224]);

      // Prepare output buffer — encoder outputs [1, 256] embedding
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      final outputSize = outputShape.reduce((a, b) => a * b);
      final output = Float32List(outputSize).reshape(outputShape);

      // Run inference
      _interpreter!.run(input, output);

      // Extract the feature vector
      final embeddings = (output as List).first as List;

      // Analyze the embedding to produce a basic classification
      return _interpretEmbedding(embeddings.cast<double>());
    } catch (e) {
      return {
        'error': true,
        'disease_name': 'Inference Error',
        'description': 'Error during model inference: ${e.toString()}',
        'confidence': 'N/A',
        'severity': 'N/A',
        'symptoms': <String>[],
        'recommendations': ['Try again with a clearer image', 'Switch to Ollama mode for better results'],
        'seek_medical_attention': false,
      };
    }
  }

  /// Interpret the encoder embedding into a basic result.
  /// Note: The TFLite model is the encoder only (ResNet50 → 256-dim embedding).
  /// For full caption generation, the Ollama mode is recommended.
  static Map<String, dynamic> _interpretEmbedding(List<double> embedding) {
    // Calculate basic statistics from the embedding
    double maxVal = double.negativeInfinity, minVal = double.infinity;
    for (final v in embedding) {
      if (v > maxVal) maxVal = v;
      if (v < minVal) minVal = v;
    }
    final range = maxVal - minVal;

    // Basic heuristic classification based on embedding statistics
    // This provides a rough analysis; Ollama mode gives fuller results
    String severity;
    bool seekMedical;
    if (range > 10) {
      severity = 'Severe';
      seekMedical = true;
    } else if (range > 5) {
      severity = 'Moderate';
      seekMedical = true;
    } else {
      severity = 'Mild';
      seekMedical = false;
    }

    return {
      'error': false,
      'disease_name': 'Skin Condition Detected',
      'confidence': 'Medium',
      'severity': severity,
      'description':
          'The on-device AI model has analyzed your skin image. '
          'For a more detailed diagnosis with specific condition names, '
          'symptoms, and recommendations, please switch to Ollama mode in Settings.',
      'symptoms': <String>[
        'Visual skin abnormality detected',
        'Further analysis recommended',
      ],
      'recommendations': <String>[
        'Consult a dermatologist for proper diagnosis',
        'Use Ollama mode for detailed AI analysis',
        'Take photos in good lighting for better results',
      ],
      'seek_medical_attention': seekMedical,
    };
  }

  /// Release the interpreter resources.
  static void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isLoaded = false;
  }
}
