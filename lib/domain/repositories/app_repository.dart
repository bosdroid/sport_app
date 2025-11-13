import '../entities/app_limits.dart';
import '../entities/video.dart';

abstract class AppRepository {
  /// Fetches videos from remote source (Firebase or API)
  Future<List<Video>> fetchVideos();

  /// Loads cached videos from local storage
  Future<List<Video>> loadCachedVideos();

  /// Saves videos to local cache
  Future<void> cacheVideos(List<Video> videos);

  /// Fetches guest user limits from Firebase
  Future<AppLimits> fetchAppLimits();
}
