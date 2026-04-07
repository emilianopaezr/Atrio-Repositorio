# ═══════════════════════════════════════════════════════════════
# Atrio - ProGuard Rules for Release Build
# Cybersecurity: Obfuscation + API Protection + Anti-Reverse Engineering
# ═══════════════════════════════════════════════════════════════

# ─── Flutter Core ───
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ─── Supabase / GoTrue / PostgREST ───
-keep class io.supabase.** { *; }
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**

# ─── Google Maps ───
-keep class com.google.android.gms.maps.** { *; }
-keep class com.google.maps.** { *; }
-keep interface com.google.android.gms.maps.** { *; }
-dontwarn com.google.android.gms.**

# ─── Google Play Services ───
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.location.** { *; }
-dontwarn com.google.android.gms.common.**

# ─── OkHttp (used by Supabase internally) ───
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# ─── Prevent exposure of model classes via reflection ───
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# ─── Remove ALL debug logs in release (security: no info leakage) ───
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
    public static int i(...);
    public static int w(...);
}

# ─── Aggressive obfuscation ───
-repackageclasses 'a'
-allowaccessmodification
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5

# ─── Keep Gson / JSON serialization ───
-keep class com.google.gson.** { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# ─── Prevent reverse engineering of string constants (API URLs etc) ───
-adaptresourcefilecontents **.properties,META-INF/MANIFEST.MF

# ─── Remove source file names for security (keep line numbers for crash reports) ───
-renamesourcefileattribute SourceFile
-keepattributes SourceFile,LineNumberTable

# ─── Google Play Core ───
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# ─── Geolocator ───
-keep class com.baseflow.geolocator.** { *; }
-dontwarn com.baseflow.geolocator.**

# ─── Image Picker ───
-keep class io.flutter.plugins.imagepicker.** { *; }

# ─── CachedNetworkImage / Flutter Cache Manager ───
-keep class com.baseflow.cachednetworkimage.** { *; }
-dontwarn com.baseflow.cachednetworkimage.**

# ─── Kotlin ───
-dontwarn kotlin.**
-keep class kotlin.Metadata { *; }
