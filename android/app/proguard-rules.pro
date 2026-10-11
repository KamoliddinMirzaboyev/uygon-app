# Flutter + plugins ship their own consumer rules; keep the alarm plugin's
# native classes (they are started by the system through the manifest).
-keep class com.gdelataillade.alarm.** { *; }
-keep class uz.uygon.uygon.** { *; }
-dontwarn com.google.android.play.core.**
