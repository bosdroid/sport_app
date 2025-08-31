class ImageModel {
  final String id;
  final String url;
  final String description;
  final int order;

  ImageModel({
    required this.id,
    required this.url,
    required this.description,
    required this.order,
  });

  /// Convert JSON to ImageModel
  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      id: json['id'] ?? '',
      url: json['url'] ?? '',
      description: json['description'] ?? '',
      order: json['order'] ?? 0,
    );
  }

  /// Convert ImageModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'description': description,
      'order': order,
    };
  }
}
