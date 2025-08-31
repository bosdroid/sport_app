class Log {
  final String id;
  final String title;
  final String description;
  final String type;
  bool isActive;
  int timestamp;
  int? resetTimestamp;
  int number; // For Number input
  String? text; // For Text input
  bool toggle;
  int time;
  bool changes;
  List<int> days;

  Log({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.isActive = false,
    required this.timestamp,
    required this.resetTimestamp,
    this.number = 0,
    this.text,
    this.toggle =false,
    this.time = 0,
    this.changes = false,
    this.days = const [],
  });

  factory Log.fromMap(Map<String, dynamic> map, String id) {
    return Log(
      id: id,
      title: map['title'] as String,
      description: map['description'] as String,
      type: map['type'] as String,
      isActive: map['isActive'] as bool? ?? false,
      timestamp: map['timestamp'] as int,
      resetTimestamp: map['resetTimestamp'] ?? 0,
      number: map['number'] ?? 0,
      text: map['text'] as String?,
      toggle: map['toggle'] ?? false,
      time: map['time'] ?? 0,
      days: List<int>.from(map['days'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'isActive': isActive,
      'timestamp': timestamp,
      'resetTimestamp': resetTimestamp,
      'number': number,
      'text': text,
      'toggle': toggle,
      'time':time,
      'days': days,
    };
  }

  Log copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    bool? isActive,
    int? timestamp,
    int? resetTimestamp,
    int? number,
    String? text,
    bool? toggle,
    int? time,
    bool? changes,
    List<int>? days,
  }) {
    return Log(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      timestamp: timestamp ?? this.timestamp,
      resetTimestamp: resetTimestamp ?? this.resetTimestamp,
      number: number ?? this.number,
      text: text ?? this.text,
      toggle: toggle ?? this.toggle,
      time: time ?? this.time,
      changes: changes ?? this.changes,
      days: days ?? this.days,
    );
  }

  bool isActiveOnDay(int day) {
    return days.contains(day);
  }

  Log resetValues() {
    return Log(
      id: id,
      title: title,
      description: description,
      type: type,
      isActive: isActive,
      timestamp: timestamp,
      resetTimestamp: DateTime.now().millisecondsSinceEpoch,
      number: 0,
      text: "",
      toggle: false,
      time: 0,
      changes: false,
      days: days,
    );
  }
}
