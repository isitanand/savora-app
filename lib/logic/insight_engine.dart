import 'dart:math';
import '../data/models/insight_model.dart';
import '../data/settings_service.dart';
import '../data/models/reflection_entry.dart';

class InsightEngine {
  // Public API
  List<Insight> analyze(List<ReflectionEntry> entries) {
    if (entries.isEmpty) {
      return [_analyzeReflectionFallback()];
    }

    final List<Insight> candidates = [];

    candidates.addAll(_analyzePatterns(entries));
    candidates.addAll(_analyzeEmotions(entries));
    candidates.addAll(_analyzeVelocity(entries));
    candidates.addAll(_analyzeVelocity(entries));
    candidates.addAll(_analyzeStaticWisdom(entries)); // Add static wisdom for variety
    
    // Always add a fallback reflection for variety (even if confidence is lower)
    // This ensures rotation logic always has a "Reflection" type to switch to.
    candidates.add(_analyzeReflectionFallback());
    candidates.addAll(_analyzeDelta(entries));

    // Filter valid confidence
    final validCandidates = candidates.where((i) => i.confidence >= 0.6).toList();

    // Sort by confidence descending
    validCandidates.sort((a, b) => b.confidence.compareTo(a.confidence));

    // If no strong insights, return fallback
    if (validCandidates.isEmpty) {
      return [_analyzeReflectionFallback()];
    }

    // V1 Selection Strategy:
    // Take top 3, shuffle, pick 1
    final topCount = min(3, validCandidates.length);
    final topCandidates = validCandidates.sublist(0, topCount);
    topCandidates.shuffle();
    
    // Return the chosen one (as a list for potential multi-exposure later)
    return [topCandidates.first];
  }


  // --- Analyzers ---

  String _getTone() {
    // reliable access to settings
    try {
      return SettingsService().insightTone.value;
    } catch (e) {
      return 'Supportive'; // Default
    }
  }

  List<Insight> _analyzePatterns(List<ReflectionEntry> entries) {
    final List<Insight> insights = [];
    final now = DateTime.now();
    final tone = _getTone();
    
    // 1. Time-of-Day Analysis
    final lateNightEntries = entries.where((e) => e.timestamp.hour >= 21 || e.timestamp.hour < 5).toList();
    if (lateNightEntries.length >= 3 && (lateNightEntries.length / entries.length) >= 0.3) {
      String msg;
      if (tone == 'Analytical') {
        msg = "30%+ of transaction volume detected between 21:00 and 05:00.";
      } else if (tone == 'Neutral') {
        msg = "You often spend money late at night.";
      } else {
        msg = "Late nights seem to be a time for spending. Everything okay?";
      }

      insights.add(Insight(
        message: msg,
        type: InsightType.pattern,
        confidence: 0.7 + (lateNightEntries.length / entries.length * 0.2), 
        generatedAt: now,
      ));
    }

    // 2. Day-of-Week Analysis
    final weekendEntries = entries.where((e) => e.timestamp.weekday >= 5).toList();
     if (weekendEntries.length >= 5 && (weekendEntries.length / entries.length) >= 0.5) {
      String msg;
      if (tone == 'Analytical') {
        msg = "Weekend spending density exceeds 50% of total entry count.";
      } else if (tone == 'Neutral') {
        msg = "Most of your spending happens on weekends.";
      } else {
        msg = "Your weekends are full of activity! Just keeping you in the loop.";
      }

      insights.add(Insight(
        message: msg,
        type: InsightType.pattern,
        confidence: 0.75,
        generatedAt: now,
      ));
    }

    return insights;
  }

  List<Insight> _analyzeEmotions(List<ReflectionEntry> entries) {
      final List<Insight> insights = [];
      final now = DateTime.now();
      final tone = _getTone();

      // Group by mood (Normalized)
      final Map<String, List<ReflectionEntry>> moodMap = {};
      for (var e in entries) {
        if (e.mood.isNotEmpty) {
          final normalized = _normalizeMood(e.mood);
          moodMap.putIfAbsent(normalized, () => []).add(e);
        }
      }

      double globalAvg = entries.isEmpty ? 0 : entries.map((e) => e.amount).reduce((a, b) => a + b) / entries.length;

      moodMap.forEach((mood, moodEntries) {
        if (moodEntries.length < 3) return;

        double moodAvg = moodEntries.map((e) => e.amount).reduce((a, b) => a + b) / moodEntries.length;

        // Detection: High spend correlation
        if (moodAvg > globalAvg * 1.3) {
           String msg;
           if (tone == 'Analytical') {
             msg = "Correlation detected: '${mood.toLowerCase()}' mood linked to 30% higher average transaction size.";
           } else if (tone == 'Neutral') {
             msg = "You spend more on average when you are ${mood.toLowerCase()}.";
           } else {
             msg = "It seems you treat yourself (or spend more) when you feel ${mood.toLowerCase()}.";
           }

           insights.add(Insight(
            message: msg,
            type: InsightType.emotional,
            confidence: 0.8,
            generatedAt: now,
          ));
        }

        // Detection: Frequency correlation
        if ((moodEntries.length / entries.length) > 0.4) {
           String msg;
           if (tone == 'Analytical') {
             msg = "Frequency dominance: '${mood.toLowerCase()}' accounts for >40% of entries.";
           } else if (tone == 'Neutral') {
             msg = "Most of your purchases are made when you are ${mood.toLowerCase()}.";
           } else {
             msg = "You're often ${mood.toLowerCase()} when you buy things. Noticed that?";
           }

           insights.add(Insight(
            message: msg,
            type: InsightType.emotional,
            confidence: 0.75,
            generatedAt: now,
          ));
        }
      });

      return insights;
  }

  List<Insight> _analyzeVelocity(List<ReflectionEntry> entries) {
      final List<Insight> insights = [];
      final now = DateTime.now();
      final tone = _getTone();
      
      final todayEntries = entries.where((e) => 
        e.timestamp.year == now.year && 
        e.timestamp.month == now.month && 
        e.timestamp.day == now.day
      ).toList();

      if (todayEntries.isEmpty) return [];

      // Fix: Use extension properly or simple fold
      double todayTotal = 0;
      for (var e in todayEntries) todayTotal += e.amount;
      
      final pastEntries = entries.where((e) => 
        !(e.timestamp.year == now.year && 
          e.timestamp.month == now.month && 
          e.timestamp.day == now.day)
      ).toList();

      if (pastEntries.isNotEmpty) {
        final firstDate = pastEntries.map((e) => e.timestamp).reduce((a, b) => a.isBefore(b) ? a : b);
        final daysDiff = now.difference(firstDate).inDays + 1; 
        
        double pastTotal = 0;
        for (var e in pastEntries) pastTotal += e.amount;
        final dailyAvg = pastTotal / daysDiff;

        // Check acceleration
        if (todayTotal > dailyAvg * 1.5 && todayTotal > 1000) { 
          String msg;
          if (tone == 'Analytical') {
            msg = "Velocity Alert: Daily spend is >150% of historical average.";
          } else if (tone == 'Neutral') {
            msg = "Spending is higher today than your average.";
          } else {
            msg = "Whoa, spending picked up sharply today! Just a heads up.";
          }

          insights.add(Insight(
            message: msg,
            type: InsightType.velocity,
            confidence: 0.85, 
            generatedAt: now,
          ));
        }
      }
      
      // Burst detection
      if (todayEntries.length >= 4) {
         String msg;
         if (tone == 'Analytical') {
            msg = "High Frequency: 4+ transactions recorded in 24h window.";
         } else if (tone == 'Neutral') {
            msg = "You have made several transactions today.";
         } else {
            msg = "Busy day? You've had quite a few transactions today.";
         }

         insights.add(Insight(
            message: msg,
            type: InsightType.velocity,
            confidence: 0.65,
            generatedAt: now,
          ));
      }

      return insights;
  }

  List<Insight> _analyzeDelta(List<ReflectionEntry> entries) {
      final now = DateTime.now();
      final oneWeekAgo = now.subtract(Duration(days: 7));
      final tone = _getTone();
      
      final recentEntries = entries.where((e) => e.timestamp.isAfter(oneWeekAgo)).toList();
      final olderEntries = entries.where((e) => e.timestamp.isBefore(oneWeekAgo)).toList();
      
      if (recentEntries.isEmpty || olderEntries.isEmpty) return [];
      
      int recentImpulsive = recentEntries.where((e) => e.context.toLowerCase() == 'impulsive').length;
      int olderImpulsive = olderEntries.where((e) => e.context.toLowerCase() == 'impulsive').length;
      
      double recentRatio = recentEntries.isEmpty ? 0 : recentImpulsive / recentEntries.length;
      double olderRatio = olderEntries.isEmpty ? 0 : olderImpulsive / olderEntries.length;
      
      if (olderRatio > 0.3 && recentRatio < 0.1) {
         String msg;
         if (tone == 'Analytical') {
            msg = "Trend Change: Impulsive entry ratio dropped from >30% to <10%.";
         } else if (tone == 'Neutral') {
            msg = "You are making fewer impulsive purchases recently.";
         } else {
            msg = "You've really cut down on impulsive buying recently. Proud of you!";
         }

         return [Insight(
            message: msg,
            type: InsightType.change,
            confidence: 0.75,
            generatedAt: now,
          )];
      }

      return [];
  }

  Insight _analyzeReflectionFallback() {
    final tone = _getTone();
    final List<String> prompts;

    if (tone == 'Analytical') {
      prompts = [
        "Data accumulation in progress. Continue logging.",
        "Pattern recognition requires more data points.",
        "Expenditure baseline is forming.",
        "Metrics are stable. No anomalies detected.",
      ];
    } else if (tone == 'Neutral') {
      prompts = [
        "No strong patterns observed today.",
        "Keep logging to reveal more patterns.",
        "Your spending has been consistent.",
        "Review your latest entries for accuracy.",
      ];
    } else {
      prompts = [
        "No strong patterns today. How did the day feel?",
        "Nothing stood out yet. Keep logging to reveal patterns.",
        "Your spending was calm and consistent recently.",
        "Money is a signal. What is yours telling you today?",
      ];
    }

    return Insight(
      message: prompts[Random().nextInt(prompts.length)],
      type: InsightType.reflection,
      confidence: 0.5, 
      generatedAt: DateTime.now(),
      isNew: false, 
    );
  }

  List<Insight> _analyzeStaticWisdom(List<ReflectionEntry> entries) {
    // These remain generic/supportive as they are "wisdom", but we can slightly tweak or just leave them.
    // Ideally wisdom is always supportive/philosophical.
    // Let's filter slightly based on tone
    final tone = _getTone();
    
    if (tone == 'Analytical') {
       // Analytical users might prefer facts over quotes
       return [
         "Compound interest is the eighth wonder of the world.",
         "Tracking expense frequency reduces impulse buying by 20%.",
         "The average millionaire saves 20% of their income.",
         "Inflation erodes purchasing power; investment combats it."
       ].map((msg) => Insight(
        message: msg,
        type: InsightType.reflection,
        confidence: 0.4,
        generatedAt: DateTime.now(),
        isNew: false
       )).toList();
    }
    
    final tips = [
      "Small daily saves add up to big safety nets.",
      "Tracking every expense builds subconscious awareness.",
      "Impulsive buying often masks a different emotional need.",
      "Wait 24 hours before making a large unplanned purchase.",
      "Financial clarity brings peace of mind.",
      "Your budget is a tool for freedom, not restriction.",
      "Not spending is the same as earning tax-free income.",
      "Invest in experiences that become good memories.",
      "Reviewing your spending helps align money with values.",
      "A mindful pause before paying changes everything."
    ];

    return tips.map((msg) => Insight(
      message: msg,
      type: InsightType.reflection, 
      confidence: 0.4, 
      generatedAt: DateTime.now(),
      isNew: false,
    )).toList();
  }

  String _normalizeMood(String raw) {
    final lower = raw.toLowerCase().trim();
    if (['happy', 'joyful', 'excited', 'great', 'content'].contains(lower)) return 'Joyful';
    if (['sad', 'down', 'depressed', 'low', 'unhappy'].contains(lower)) return 'Low';
    if (['calm', 'relaxed', 'peaceful', 'chill', 'zen'].contains(lower)) return 'Calm';
    if (['stressed', 'anxious', 'worried', 'tense', 'panic'].contains(lower)) return 'Stressed';
    if (['tired', 'exhausted', 'fatigued', 'lazy', 'sleepy'].contains(lower)) return 'Tired';
    if (['angry', 'frustrated', 'annoyed', 'mad'].contains(lower)) return 'Frustrated';
    return raw; 
  }
}

// Extension helper for sum
extension SumIterable on Iterable<double> {
  // Dart doesn't have a built-in sum for iterables, using reduce or fold locally
}

// Extension for fold because I used .folder above by mistake/habit
extension ListFold on List<ReflectionEntry> {
  T folder<T>(T initialValue, T Function(T previousValue, ReflectionEntry element) combine) {
    var value = initialValue;
    for (var element in this) {
      value = combine(value, element);
    }
    return value;
  }
}
