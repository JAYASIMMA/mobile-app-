# ProGuard rules for TensorFlow Lite
-keep class org.tensorflow.lite.** { *; }
-keep class com.google.android.gms.tflite.** { *; }

# Flutter specific rules (usually handled by Flutter, but good to have)
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.editing.** { *; }
