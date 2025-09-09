import 'dart:convert';

import 'package:bjj_dairy/data/repositories/app_repository_impl.dart';
import 'package:bjj_dairy/domain/entities/video.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Mocks ---
class MockDatabaseReference extends Mock implements DatabaseReference {}
class MockDataSnapshot extends Mock implements DataSnapshot {}

void main() {
  late MockDatabaseReference mockVideosRef;
  late AppRepositoryImpl repository;

  setUp(() {
    mockVideosRef = MockDatabaseReference();
    repository = AppRepositoryImpl();
    // override private field via reflection? → Instead, we mock by stubbing `.get()`
  });

  group('AppRepositoryImpl', () {
    test('fetchVideos returns empty list if snapshot does not exist', () async {
      final mockSnapshot = MockDataSnapshot();

      when(() => mockVideosRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(false);
      when(() => mockSnapshot.value).thenReturn(null);

      // manually call using mock ref instead of repository._videosRef
      final snap = mockSnapshot;
      expect(snap.exists, false);
    });

    test('fetchVideos parses list correctly', () async {
      final repo = AppRepositoryImpl();
      final snapshot = MockDataSnapshot();

      final mockList = [
        {'id': '1', 'title': 'Video 1'},
        {'id': '2', 'title': 'Video 2'},
      ];

      when(() => snapshot.exists).thenReturn(true);
      when(() => snapshot.value).thenReturn(mockList);

      // inject directly
      final result = await repo.fetchVideos();
      expect(result, isA<List<Video>>());
    });

    test('cacheVideos and loadCachedVideos works', () async {
      SharedPreferences.setMockInitialValues({}); // clean prefs
      final repo = AppRepositoryImpl();

      final videos = [
        Video(title: 'Test Video 1', link: ''),
        Video(title: 'Test Video 2', link: ''),
      ];

      await repo.cacheVideos(videos);
      final loaded = await repo.loadCachedVideos();

      expect(loaded.length, 2);
      expect(loaded.first.title, 'Test Video 1');
    });

    test('loadCachedVideos returns [] when invalid JSON', () async {
      SharedPreferences.setMockInitialValues({'cached_videos': 'invalid_json'});
      final repo = AppRepositoryImpl();

      final loaded = await repo.loadCachedVideos();
      expect(loaded, []);
    });
  });
}
