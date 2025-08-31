class Favourite {
  final String id;
  final String userId;
  final String planId;

  Favourite({
    required this.id,
    required this.userId,
    required this.planId,
  });

  // Factory constructor to create Favourite from a Map (e.g., Firebase snapshot)
  factory Favourite.fromMap(Map<String, dynamic> map) {
    return Favourite(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      planId: map['planId'] ?? '',
    );
  }

  // Convert Favourite instance to a Map (for uploading to Firebase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'planId': planId,
    };
  }
}
