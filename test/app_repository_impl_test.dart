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
    repository = AppRepositoryImpl(videosRef: mockVideosRef);
  });

  group('AppRepositoryImpl', () {
    test('fetchVideos returns empty list if snapshot does not exist', () async {
      final mockSnapshot = MockDataSnapshot();

      when(() => mockVideosRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(false);
      when(() => mockSnapshot.value).thenReturn(null);

      final result = await repository.fetchVideos();
      expect(result, []);
    });

    test('fetchVideos parses list correctly', () async {
      final snapshot = MockDataSnapshot();

      final mockList = [
        {'id': '1', 'title': 'Video 1'},
        {'id': '2', 'title': 'Video 2'},
      ];

      when(() => mockVideosRef.get()).thenAnswer((_) async => snapshot);
      when(() => snapshot.exists).thenReturn(true);
      when(() => snapshot.value).thenReturn(mockList);

      final result = await repository.fetchVideos();
      expect(result, isA<List<Video>>());
      expect(result.length, 2);
    });

    test('cacheVideos and loadCachedVideos works', () async {
      SharedPreferences.setMockInitialValues({});
      repository = AppRepositoryImpl(videosRef: mockVideosRef);

      final videos = [
        Video(title: 'Test Video 1', link: ''),
        Video(title: 'Test Video 2', link: ''),
      ];

      await repository.cacheVideos(videos);
      final loaded = await repository.loadCachedVideos();

      expect(loaded.length, 2);
      expect(loaded.first.title, 'Test Video 1');
    });

    test('loadCachedVideos returns [] when invalid JSON', () async {
      SharedPreferences.setMockInitialValues({'cached_videos': 'invalid_json'});
      repository = AppRepositoryImpl(videosRef: mockVideosRef);

      final loaded = await repository.loadCachedVideos();
      expect(loaded, []);
    });

    test('fetchVideos parses map value correctly', () async {
      final snapshot = MockDataSnapshot();

      final mockMap = {
        'v1': {'id': '1', 'title': 'A'},
        'v2': {'id': '2', 'title': 'B'}
      };

      when(() => mockVideosRef.get()).thenAnswer((_) async => snapshot);
      when(() => snapshot.exists).thenReturn(true);
      when(() => snapshot.value).thenReturn(mockMap);

      final result = await repository.fetchVideos();

      expect(result.length, 2);
      expect(result.first.title, 'A');
      expect(result.last.title, 'B');
    });

    test('fetchVideos handles malformed or missing fields gracefully', () async {
      final snapshot = MockDataSnapshot();

      final mockList = [
        {'id': '1', 'title': null}, // missing title
        null,                       // null item should be skipped
        {'link': 'some-link'},      // missing title field
      ];

      when(() => mockVideosRef.get()).thenAnswer((_) async => snapshot);
      when(() => snapshot.exists).thenReturn(true);
      when(() => snapshot.value).thenReturn(mockList);

      final result = await repository.fetchVideos();
      expect(result, isA<List<Video>>());
      expect(result.length, 2); // two valid items (non-null maps)
      expect(result.first.title, isNotNull);
    });

    test('fetchVideos returns empty list if snapshot.value is invalid type', () async {
      final snapshot = MockDataSnapshot();

      when(() => mockVideosRef.get()).thenAnswer((_) async => snapshot);
      when(() => snapshot.exists).thenReturn(true);
      when(() => snapshot.value).thenReturn("invalid_data");

      final result = await repository.fetchVideos();
      expect(result, []);
    });

    test('fetchVideos propagates exceptions from Firebase .get()', () async {
      when(() => mockVideosRef.get()).thenThrow(Exception("Permission denied"));

      expect(() async => await repository.fetchVideos(), throwsException);
    });

    test('loadCachedVideos returns [] when no cache key exists', () async {
      SharedPreferences.setMockInitialValues({});
      repository = AppRepositoryImpl(videosRef: mockVideosRef);

      final result = await repository.loadCachedVideos();
      expect(result, []);
    });

    test('loadCachedVideos returns [] for empty JSON list', () async {
      SharedPreferences.setMockInitialValues({'cached_videos': '[]'});
      repository = AppRepositoryImpl(videosRef: mockVideosRef);

      final result = await repository.loadCachedVideos();
      expect(result, []);
    });

    test('loadCachedVideos handles partial JSON entries', () async {
      final jsonData = jsonEncode([
        {'title': 'Vid 1'}, // no link
        {'link': 'url'},    // no title
      ]);
      SharedPreferences.setMockInitialValues({'cached_videos': jsonData});
      repository = AppRepositoryImpl(videosRef: mockVideosRef);

      final result = await repository.loadCachedVideos();
      expect(result.length, 2);
      expect(result.first.title, 'Vid 1');
    });

    test('cacheVideos works with empty list', () async {
      SharedPreferences.setMockInitialValues({});
      repository = AppRepositoryImpl(videosRef: mockVideosRef);

      await repository.cacheVideos([]);
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('cached_videos');

      expect(jsonStr, '[]');

      final loaded = await repository.loadCachedVideos();
      expect(loaded, []);
    });

    test('cacheVideos stores and loads emoji/unicode safely', () async {
      SharedPreferences.setMockInitialValues({});
      repository = AppRepositoryImpl(videosRef: mockVideosRef);

      final videos = [
        Video(title: '😊 Video 🎬', link: 'https://link.com')
      ];

      await repository.cacheVideos(videos);
      final loaded = await repository.loadCachedVideos();

      expect(loaded.first.title, '😊 Video 🎬');
      expect(loaded.first.link, 'https://link.com');
    });


  });
}
