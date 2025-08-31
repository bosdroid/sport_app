class Folder {
  final String? id;
  final String? userId;
  String? name;
  final int order;
  final String? shareId; // Unique shareable ID
  String access; // private/public/specific
  List<String> allowedUsers; // for 'specific' access

  Folder({
    this.id,
    this.userId,
    this.name,
    this.order = 0,
    this.shareId,
    this.access = 'private',
    this.allowedUsers = const [],
  });

  factory Folder.fromMap(Map<String, dynamic> data) {
    return Folder(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      order: data['order'] ?? 0,
      shareId: data['shareId'],
      access: data['access'] ?? 'private',
      allowedUsers: List<String>.from(data['allowedUsers'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'order': order,
      'shareId': shareId,
      'access': access,
      'allowedUsers': allowedUsers,
    };
  }

  Folder copyWith({
    String? id,
    String? userId,
    String? name,
    int? order,
    String? shareId,
    String? access,
    List<String>? allowedUsers,
  }) {
    return Folder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      order: order ?? this.order,
      shareId: shareId ?? this.shareId,
      access: access ?? this.access,
      allowedUsers: allowedUsers ?? this.allowedUsers,
    );
  }
}
