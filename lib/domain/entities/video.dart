class Video {
  final String title;
  final String link;

  Video({
    required this.title,
    required this.link,
  });

  // Factory constructor to create a Video instance from JSON
  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      title: json['title'] ?? '',
      link: json['link'] ?? '',
    );
  }

  // Method to convert a Video instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'link': link,
    };
  }
}
