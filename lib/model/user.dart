class User {
  final String id;
  final String username;
  final String email;
  final String type;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.type,
  });

  // Convert UserModel to Map (e.g., for Firestore or JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'type': type,
    };
  }

  // Create UserModel from Map (e.g., from Firestore or JSON)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      type: map['type'] ?? '',
    );
  }
}
