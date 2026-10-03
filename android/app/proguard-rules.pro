# audio_service: Keep the AudioService and MediaButtonReceiver classes
# that are referenced in AndroidManifest.xml and used at runtime.
-keep class com.ryanheise.audioservice.** { *; }

# Keep the notification icon resource ID references
-keepclassmembers class **.R$drawable {
    public static <fields>;
}
