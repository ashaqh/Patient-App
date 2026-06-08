# Required by flutter_local_notifications (< v19) / Gson in release builds.
# Prevents TypeToken generic signature stripping that breaks
# pendingNotificationRequests() / loadScheduledNotifications().
-keepattributes Signature
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
