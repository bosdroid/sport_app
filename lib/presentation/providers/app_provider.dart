import 'package:flutter/foundation.dart';
import '../../domain/entities/video.dart';
import '../../domain/repositories/app_repository.dart';

class AppProvider with ChangeNotifier {
  final AppRepository _repository;

  AppProvider(this._repository);

  List<Video> _videos = [];
  List<Video> get videos => _videos;

  Future<void> fetchAndSaveVideos() async {
    _videos = await _repository.fetchVideos();
    notifyListeners();
    await _repository.cacheVideos(_videos);
  }

  Future<void> loadVideosFromPrefs() async {
    _videos = await _repository.loadCachedVideos();
    notifyListeners();
  }
}
