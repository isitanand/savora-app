class MonthlyIntent {
  final String id;
  final String monthYear; // "2024-12"
  final String intentText;
  final DateTime createdAt;

  const MonthlyIntent({
    required this.id,
    required this.monthYear,
    required this.intentText,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'monthYear': monthYear,
      'intentText': intentText,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MonthlyIntent.fromJson(Map<String, dynamic> json) {
    return MonthlyIntent(
      id: json['id'] as String,
      monthYear: json['monthYear'] as String,
      intentText: json['intentText'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
