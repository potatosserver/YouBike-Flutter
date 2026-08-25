# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Google Play Core (for deferred components) - ignore missing classes
-dontwarn com.google.android.play.core.**

# Material Components
-keep class com.google.android.material.** { *; }

# OkHttp / Retrofit (if used via plugins)
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }

# Gson
-keep class com.google.gson.** { *; }

# Kotlin coroutines
-keep class kotlinx.coroutines.** { *; }

# Keep native libraries
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes EnclosingMethod

# Keep Flutter generated code
-keep class **GeneratedPluginRegistrant { *; }
-keep class **PluginRegistry { *; }

# Avoid obfuscating resource names (for shrinkResources)
-keepclassmembers class **.R$* {
    public static <fields>;
}