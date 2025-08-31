import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/video.dart';
import '../../domain/repositories/app_repository.dart';

class AppRepositoryImpl implements AppRepository {
  final DatabaseReference _videosRef =
  FirebaseDatabase.instance.ref().child('VIDEOS');

  @override
  Future<List<Video>> fetchVideos() async {
    final snap = await _videosRef.get();
    if (!snap.exists || snap.value == null) return [];

    final List<Video> parsed = [];

    if (snap.value is List) {
      // Handle list case
      final list = snap.value as List;
      for (final item in list) {
        if (item != null) {
          parsed.add(Video.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    } else if (snap.value is Map) {
      // Handle map case
      final map = Map<String, dynamic>.from(snap.value as Map);
      for (final item in map.values) {
        parsed.add(Video.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    return parsed;
  }

  @override
  Future<List<Video>> loadCachedVideos() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('cached_videos');
    if (jsonStr == null) return [];

    try {
      final decoded = jsonDecode(jsonStr) as List<dynamic>;
      return decoded
          .map<Video>((v) => Video.fromJson(Map<String, dynamic>.from(v)))
          .toList();
    } catch (_) {
      await prefs.remove('cached_videos');
      return [];
    }
  }

  @override
  Future<void> cacheVideos(List<Video> videos) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(videos.map((v) => v.toJson()).toList());
    await prefs.setString('cached_videos', jsonStr);
  }
}
