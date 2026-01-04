import 'package:web/web.dart' as web;
import 'package:shared_preferences/shared_preferences.dart';

class Notify {
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? false;
  }
  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    if (enabled) {
      try {
        web.Notification.requestPermission();
      } catch (_) {}
    }
  }
  static Future<void> maybeNotify(String title, String body) async {
    try {
      final enabled = await isEnabled();
      if (!enabled) return;
      if (web.Notification.permission == 'granted') {
        web.Notification(title, web.NotificationOptions(body: body));
      } else {
        web.Notification.requestPermission();
        if (web.Notification.permission == 'granted') {
          web.Notification(title, web.NotificationOptions(body: body));
        }
      }
    } catch (_) {}
  }
}
