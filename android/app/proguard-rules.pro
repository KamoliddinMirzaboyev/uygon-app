# Flutter + plugins ship their own consumer rules; keep the alarm plugin's
# native classes (they are started by the system through the manifest).
-keep class com.gdelataillade.alarm.** { *; }
-keep class uz.uygon.uygon.** { *; }
-dontwarn com.google.android.play.core.**

# Keep Flutter Plugins & Platform Channels
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }

# Sensors Plus & Pedometer
-keep class dev.fluttercommunity.plus.sensors.** { *; }
-keep class com.example.pedometer.** { *; }

# Mobile Scanner & ML Kit
-keep class com.google.mlkit.** { *; }
-keep class dev.steenbakker.mobile_scanner.** { *; }
-dontwarn com.google.mlkit.**

# Kotlin attributes
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
-dontwarn kotlin.**
