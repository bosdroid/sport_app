class AppLimits {
  final int maxFoldersForGuest;
  final int maxCardsForGuest;

  AppLimits({
    required this.maxFoldersForGuest,
    required this.maxCardsForGuest,
  });

  factory AppLimits.fromJson(Map<String, dynamic> json) {
    return AppLimits(
      maxFoldersForGuest: json['maxFoldersForGuest'] ?? 1,
      maxCardsForGuest: json['maxCardsForGuest'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'maxFoldersForGuest': maxFoldersForGuest,
    'maxCardsForGuest': maxCardsForGuest,
  };
}
