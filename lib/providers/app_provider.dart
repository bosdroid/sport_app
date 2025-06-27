import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/video.dart';


class AppProvider with ChangeNotifier {
  final DatabaseReference _videosRef =
  FirebaseDatabase.instance.ref().child('VIDEOS');

  // -------- state -----------------------------------------------------------
  List<Video> _videos = [];
  List<Video> get videos => _videos;

  // -------- public API ------------------------------------------------------
  Future<void> fetchAndSaveVideos() async {
    final snap = await _videosRef.get();
    if (!snap.exists || snap.value == null) return;

    final List<Video> parsed = [];

    // ─── List case: [ {title:…, link:…}, … ] ──────────────────────────────
    if (snap.value is List) {
      final list = snap.value as List;
      for (final item in list) {
        if (item != null) {
          parsed.add(Video.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    // ─── Map case: { "0": {title:…, link:…}, "1": … } ─────────────────────
    else if (snap.value is Map) {
      final map = Map<String, dynamic>.from(snap.value as Map);
      for (final item in map.values) {
        parsed.add(Video.fromJson(Map<String, dynamic>.from(item)));
      }
    }

    _videos = parsed;
    if (kDebugMode) print('Fetched videos: $_videos');

    notifyListeners();
    await _cacheVideos(); // unchanged
  }

  Future<void> loadVideosFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('cached_videos');

    if (jsonStr == null) return;

    try {
      final decoded = jsonDecode(jsonStr) as List<dynamic>;
      _videos = decoded
          .map<Video>((v) => Video.fromJson(Map<String, dynamic>.from(v)))
          .toList();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Corrupted cached_videos, clearing: $e');
      await prefs.remove('cached_videos');
      _videos = [];
    }
  }

  // -------- helpers ---------------------------------------------------------
  Future<void> _cacheVideos() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_videos.map((v) => v.toJson()).toList());
    await prefs.setString('cached_videos', jsonStr);
  }
}
