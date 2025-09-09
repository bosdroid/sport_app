import 'package:bjj_dairy/domain/entities/video.dart';
import 'package:bjj_dairy/presentation/providers/app_provider.dart';
import 'package:bjj_dairy/domain/repositories/app_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAppRepository extends Mock implements AppRepository {}

void main() {
  late MockAppRepository mockRepository;
  late AppProvider provider;

  setUp(() {
    mockRepository = MockAppRepository();
    provider = AppProvider(mockRepository);
  });

  test('fetchAndSaveVideos updates videos and calls cache', () async {
    final videos = [Video(title: 'Video 1', link: '')];

    when(() => mockRepository.fetchVideos()).thenAnswer((_) async => videos);
    when(() => mockRepository.cacheVideos(any())).thenAnswer((_) async {});

    await provider.fetchAndSaveVideos();

    expect(provider.videos, equals(videos));
    verify(() => mockRepository.cacheVideos(videos)).called(1);
  });

  test('loadVideosFromPrefs updates videos', () async {
    final videos = [Video(title: 'FromPrefs', link: '')];

    when(() => mockRepository.loadCachedVideos()).thenAnswer((_) async => videos);

    await provider.loadVideosFromPrefs();

    expect(provider.videos, equals(videos));
  });
}
