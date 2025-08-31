import 'package:shared_preferences/shared_preferences.dart';

class AppUsageTracker {
  static const _openCountKey = 'app_open_count';

  static Future<int> incrementAndGetOpenCount() async {
    final prefs = await SharedPreferences.getInstance();
    int count = prefs.getInt(_openCountKey) ?? 0;
    count++;
    await prefs.setInt(_openCountKey, count);
    return count;
  }

  static Future<void> resetOpenCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_openCountKey, 0);
  }
}
