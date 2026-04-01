enum InsightType {
  pattern,      
  change,       
  emotional,    
  velocity,     
  reflection    
}

class Insight {
  final String message;       
  final InsightType type;     
  final double confidence;    
  final bool isNew;           
  final DateTime generatedAt; 

  Insight({
    required this.message,
    required this.type,
    required this.confidence,
    this.isNew = true,
    required this.generatedAt,
  });
}
