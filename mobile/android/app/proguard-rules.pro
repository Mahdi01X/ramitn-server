# Flutter-specific ProGuard rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Keep audioplayers
-keep class xyz.luan.audioplayers.** { *; }

# Keep socket.io
-keep class io.socket.** { *; }

