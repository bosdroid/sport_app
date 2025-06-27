import 'package:bjj_dairy/model/video_entry.dart';

class Plan {
  final String id;
  final String userId;
  String title;
  String description;
  List<VideoEntry>? videos;
  final int timestamp;
  List<String> from; // Parent cards
  List<String> to; // Child cards
  bool isExpanded;
  List<String> tags;
  String status;
  List<String> images;
  String note;
  String folderId;

  Plan(
      {required this.id,
        required this.userId,
      required this.title,
      required this.description,
      required this.videos,
      required this.timestamp,
      this.from = const [],
      this.to = const [],
      this.isExpanded = false,
      this.tags = const [],
      this.status = 'neutral',
      this.images = const [],
      this.note = '',
      this.folderId = ''});

  factory Plan.fromMap(Map<String, dynamic> data) {
    return Plan(
        id: data['id'] ?? '',
        userId: data['userId'] ?? '',
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        videos: data['videos'] == null
            ? []
            : (data['videos'] as List<dynamic>)
                .map((e) => VideoEntry.fromMap(Map<String, dynamic>.from(e)))
                .toList(),
        timestamp: data['timestamp'] ?? 0,
        from: _extractValidKeys(data["from"]),
        to: _extractValidKeys(data["to"]),
        tags: List<String>.from(data['tags'] ?? []),
        status: data['status'] ?? 'neutral',
        images: List<String>.from(data['images'] ?? []),
        note:data['note'] ?? '',
        folderId:data['folderId'] ?? '');
  }

  Map<String, dynamic> toMap() {
    return {
      'id':id,
      'userId':userId,
      'title': title,
      'description': description,
      'videos': videos!.map((v) => v.toMap()).toList(),
      'timestamp': timestamp,
      'from': from,
      'to': to,
      'tags': tags,
      'status': status,
      'images': images,
      'note':note,
      'folderId':folderId
    };
  }

  static List<String> _extractValidKeys(dynamic field) {
    if (field is Map) {
      return field.keys
          .where((key) =>
              key is String &&
              !RegExp(r'^\d+$').hasMatch(key)) // Ignore numeric keys
          .map((key) => key.toString())
          .toList();
    }
    return [];
  }

  factory Plan.empty() {
    return Plan(
        id: '',
        userId: '',
        title: '',
        description: '',
        videos: [],
        timestamp: 0,
        from: [],
        to: [],
        tags: [],
        status: 'neutral',
        images: [],
        note: '',
    folderId: '');
  }

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);

  // String get timeInMinutesSeconds {
  //   final minutes = timeInSeconds ~/ 60;
  //   final seconds = timeInSeconds % 60;
  //   return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  // }
  String timeInMinutesSeconds(int timeInSeconds) {
    final minutes = timeInSeconds ~/ 60;
    final seconds = timeInSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static int minutesSecondsToSeconds(String minutesSeconds) {
    final parts = minutesSeconds.split(':');
    if (parts.length != 2) return 0;
    final minutes = int.tryParse(parts[0]) ?? 0;
    final seconds = int.tryParse(parts[1]) ?? 0;
    return (minutes * 60) + seconds;
  }
}
