class Goal {
  final String id;
  final String title;
  final String description;
  final int timestamp;
  bool isActive;
  bool achieved; // New property for achieved status
  bool changes;
  Goal({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    this.isActive = false,
    this.achieved =false,
    this.changes = false
  });

  // Convert Goal to Map for Firebase storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'timestamp': timestamp,
      'isActive': isActive,
      'achieved': achieved,
    };
  }

  // Create Goal from Firebase data
  factory Goal.fromMap(Map<String, dynamic> map, String id) {
    return Goal(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      timestamp: map['timestamp'] ?? '',
      isActive: map['isActive'] ?? false,
      achieved: map['achieved'] ?? false,
    );
  }
}

// class Goal {
//   String? id;
//   String? title;
//   int? times;
//   int? achieved;
//   String? text;
//   String? videoUrl;
//   bool? isTextEnable;
//   bool? isVideoEnable;
//   bool? isVideoMuteUnmute;
//   String? type;
//   int? quantity;
//   int? progress;
//   int? timestamp;
//   int? successTimestamp;
//   int? resetTimestamp;
//   String? historyKey;
//   // List<Goal>? history;
//
//   Goal(
//       {this.id,
//       this.title,
//       this.times,
//       this.achieved,
//       this.text,
//       this.videoUrl,
//       this.isTextEnable,
//       this.isVideoEnable,
//       this.isVideoMuteUnmute,
//       this.type,
//       this.quantity,
//       this.progress,
//       this.timestamp,
//       this.successTimestamp,
//       this.resetTimestamp,
//       this.historyKey});
//
//   factory Goal.fromJson(Map<String, dynamic> json) {
//     return Goal(
//         id: json['id'],
//         title: json['title'],
//         times: json['times'],
//         achieved: json['achieved'],
//         text: json['text'],
//         videoUrl: json['videoUrl'],
//         isTextEnable: json['isTextEnable'],
//         isVideoEnable: json['isVideoEnable'],
//         isVideoMuteUnmute: json['isVideoMuteUnmute'],
//         type: json['type'],
//         quantity: json['quantity'],
//         progress: json['progress'],
//         timestamp: json['timestamp'],
//         successTimestamp: json['successTimestamp'],
//         resetTimestamp: json['resetTimestamp']);
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['id'] = id;
//     data['title'] = title;
//     data['times'] = times;
//     data['achieved'] = achieved;
//     data['text'] = text;
//     data['videoUrl'] = videoUrl;
//     data['isTextEnable'] = isTextEnable;
//     data['isVideoEnable'] = isVideoEnable;
//     data['isVideoMuteUnmute'] = isVideoMuteUnmute;
//     data['type'] = type;
//     data['quantity'] = quantity;
//     data['progress'] = progress;
//     data['timestamp'] = timestamp;
//     data['successTimestamp'] = successTimestamp;
//     data['resetTimestamp'] = resetTimestamp;
//     // data['history'] = history;
//     return data;
//   }
// }
