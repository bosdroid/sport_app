import 'package:flutter/foundation.dart';
import '../../domain/entities/app_limits.dart';
import '../../domain/entities/video.dart';
import '../../domain/repositories/app_repository.dart';

class AppProvider with ChangeNotifier {
  final AppRepository _repository;

  AppProvider(this._repository);

  List<Video> _videos = [];
  List<Video> get videos => _videos;

  AppLimits? _limits;
  AppLimits? get limits => _limits;

  Future<void> fetchAndSaveVideos() async {
    _videos = await _repository.fetchVideos();
    notifyListeners();
    await _repository.cacheVideos(_videos);
  }

  Future<void> loadVideosFromPrefs() async {
    _videos = await _repository.loadCachedVideos();
    notifyListeners();
  }

  Future<void> fetchLimits() async {
    _limits = await _repository.fetchAppLimits();
    print(_limits);
    notifyListeners();
  }
}
