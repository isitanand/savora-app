enum InsightType {
  pattern,      // Repeated behavior over time
  change,       // Difference vs previous period
  emotional,    // Emotion ↔ spending link
  velocity,     // Speed / acceleration of spending
  reflection    // Soft prompts when no insight is strong
}

class Insight {
  final String message;       // Human-readable text
  final InsightType type;     // Category
  final double confidence;    // 0.0 → 1.0 strength score
  final bool isNew;           // Whether user has seen it
  final DateTime generatedAt; // Timestamp for rotation logic

  Insight({
    required this.message,
    required this.type,
    required this.confidence,
    this.isNew = true,
    required this.generatedAt,
  });
}
