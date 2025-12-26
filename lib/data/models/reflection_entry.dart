class ReflectionEntry {
  final String id;
  final double amount;
  final String currencyCode;
  final DateTime timestamp;
  final String mood; // "Tired", "Stressed", "Calm", etc.
  final String context; // "Home", "Work", "Cafe", etc.
  final String note;
  final String? personName;
  final bool isSettled;

  const ReflectionEntry({
    required this.id,
    required this.amount,
    required this.currencyCode,
    required this.timestamp,
    required this.mood,
    required this.context,
    required this.note,
    this.personName,
    this.isSettled = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'currencyCode': currencyCode,
      'timestamp': timestamp.toIso8601String(),
      'mood': mood,
      'context': context,
      'note': note,
      'personName': personName,
      'isSettled': isSettled,
    };
  }

  factory ReflectionEntry.fromJson(Map<String, dynamic> json) {
    return ReflectionEntry(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currencyCode: json['currencyCode'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      mood: json['mood'] as String,
      context: json['context'] as String,
      note: json['note'] as String,
      personName: json['personName'] as String?,
      isSettled: (json['isSettled'] as bool?) ?? false,
    );
  }
}
