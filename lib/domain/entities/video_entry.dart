class VideoEntry {
  String title;
  String url;
  final String? type; // e.g., explanation, drill
  final int? timeInSeconds; // Only for YouTube
  bool isYoutubeUrl;
  final int timestamp;

  VideoEntry({
    required this.title,
    required this.url,
    required this.timestamp,
    this.type,
    this.timeInSeconds,
    this.isYoutubeUrl = false
  });

  factory VideoEntry.fromMap(Map<String, dynamic> map) => VideoEntry(
    title: map['title'] ?? '',
    url: map['url'] ?? '',
      timestamp: map['timestamp'] ?? 0,
    type: map['type'],
    timeInSeconds: map['timeInSeconds'],
    isYoutubeUrl: map['isYoutubeUrl'] ?? false
  );

  VideoEntry copyWith({
    String? title,
    String? url,
    int? timestamp,
    String? type,
    int? timeInSeconds,
    bool? isYoutubeUrl
  }) {
    return VideoEntry(
      title: title ?? this.title,
      url: url ?? this.url,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      timeInSeconds: timeInSeconds ?? this.timeInSeconds,
      isYoutubeUrl: isYoutubeUrl ?? this.isYoutubeUrl
    );
  }


  Map<String, dynamic> toMap() => {
    'title': title,
    'url': url,
    'timestamp': timestamp,
    'type': type,
    'timeInSeconds': timeInSeconds,
    'isYoutubeUrl' : isYoutubeUrl
  };

  String get timeInMinutesSeconds {
    final minutes = timeInSeconds! ~/ 60;
    final seconds = timeInSeconds! % 60;
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