import 'package:bjj_dairy/model/video_entry.dart';

import 'comment.dart';

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
  bool isShared;

  // 👇 New fields
  List<String> likedBy; // userIds who liked
  List<String> favouritedBy; // userIds who favourited
  List<Comment> comments; // list of comments

  Plan({
    required this.id,
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
    this.folderId = '',
    this.likedBy = const [],
    this.favouritedBy = const [],
    this.comments = const [],
    this.isShared = false
  });

  Plan copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    List<VideoEntry>? videos,
    int? timestamp,
    List<String>? from,
    List<String>? to,
    bool? isExpanded,
    List<String>? tags,
    String? status,
    List<String>? images,
    String? note,
    String? folderId,
    bool? isShared,
    List<String>? likedBy,
    List<String>? favouritedBy,
    List<Comment>? comments,
  }) {
    return Plan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      videos: videos != null ? List<VideoEntry>.from(videos) : videos == null && this.videos != null ? List<VideoEntry>.from(this.videos!) : [],
      timestamp: timestamp ?? this.timestamp,
      from: from != null ? List<String>.from(from) : List<String>.from(this.from),
      to: to != null ? List<String>.from(to) : List<String>.from(this.to),
      isExpanded: isExpanded ?? this.isExpanded,
      tags: tags != null ? List<String>.from(tags) : List<String>.from(this.tags),
      status: status ?? this.status,
      images: images != null ? List<String>.from(images) : List<String>.from(this.images),
      note: note ?? this.note,
      folderId: folderId ?? this.folderId,
      isShared: isShared ?? this.isShared,
      likedBy: likedBy != null ? List<String>.from(likedBy) : List<String>.from(this.likedBy),
      favouritedBy: favouritedBy != null ? List<String>.from(favouritedBy) : List<String>.from(this.favouritedBy),
      comments: comments != null ? List<Comment>.from(comments) : List<Comment>.from(this.comments),
    );
  }


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
        note: data['note'] ?? '',
        folderId: data['folderId'] ?? '',
        likedBy: List<String>.from(data['likedBy'] ?? []),
        favouritedBy: List<String>.from(data['favouritedBy'] ?? []),
      comments: (data['comments'] as Map?)?.entries.map((entry) {
        final commentMap = Map<String, dynamic>.from(entry.value);
        commentMap['id'] = entry.key; // set Firebase key as comment ID
        return Comment.fromMap(commentMap);
      }).toList() ?? [],
      isShared: data['isShared'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'videos': videos!.map((v) => v.toMap()).toList(),
      'timestamp': timestamp,
      'from': from,
      'to': to,
      'tags': tags,
      'status': status,
      'images': images,
      'note': note,
      'folderId': folderId,
      'likedBy': likedBy,
      'favouritedBy': favouritedBy,
      'comments': comments,
      'isShared': isShared
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
        folderId: '',isShared: false);
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
