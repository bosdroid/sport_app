class LogHistory {
  final String historyId;
  final int timestamp;
  final String type;
  dynamic value;

  LogHistory({
    required this.historyId,
    required this.timestamp,
    required this.type,
    this.value
  });

  factory LogHistory.fromMap(Map<String, dynamic> map, String id) {
    return LogHistory(
        historyId: map['historyId'] as String,
        timestamp: map['timestamp'] as int,
        type: map['type'] as String,
        value: map['value'] as dynamic,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'historyId': historyId,
      'timestamp': timestamp,
      'type': type,
      'value': value
    };
  }

  factory LogHistory.empty(int timestamp) {
    return LogHistory(
      historyId: '',
      timestamp: timestamp,
      type: '',
        value:''
    );
  }
}