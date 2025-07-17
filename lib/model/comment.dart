class Comment {
  final String id;
  final String userId;
  final String username;
  final String text;
  final int timestamp;

  Comment({
    required this.id,
    required this.userId,
    required this.username,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'id':id,
    'userId': userId,
    'username': username,
    'text': text,
    'timestamp': timestamp,
  };

  static Comment fromMap(Map<String, dynamic> map) => Comment(
    id: map['id'],
    userId: map['userId'],
    username: map['username'],
    text: map['text'],
    timestamp: map['timestamp'],
  );
}
