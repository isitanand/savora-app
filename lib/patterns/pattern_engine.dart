import '../data/models/reflection_entry.dart';
import 'pattern_model.dart';
import 'package:uuid/uuid.dart';

class PatternEngine {
  static const int _minThreshold = 3;

  List<BehaviorPattern> analyze(List<ReflectionEntry> entries) {
    if (entries.isEmpty) return [];

    final patterns = <BehaviorPattern>[];

    patterns.addAll(_analyzeTimeClusters(entries));
    patterns.addAll(_analyzeMoodRecurrence(entries));
    patterns.addAll(_analyzeContextClusters(entries));

    return patterns;
  }

  // Heuristic 1: Time Clusters
  List<BehaviorPattern> _analyzeTimeClusters(List<ReflectionEntry> entries) {
    int lateNightCount = 0;
    int morningCount = 0;

    for (var entry in entries) {
      final hour = entry.timestamp.hour;
      if (hour >= 23 || hour < 4) {
        lateNightCount++;
      } else if (hour >= 6 && hour < 10) {
        morningCount++;
      }
    }

    final results = <BehaviorPattern>[];

    if (lateNightCount >= _minThreshold) {
      results.add(BehaviorPattern(
        id: const Uuid().v4(),
        title: 'Often noted late at night',
        description: 'Reflections appear frequent during late night hours.',
        occurrenceCount: lateNightCount,
        tags: ['Time', 'Late Night'],
      ));
    }

    if (morningCount >= _minThreshold) {
      results.add(BehaviorPattern(
        id: const Uuid().v4(),
        title: 'Often noted in the morning',
        description: 'Reflections appear frequent in the early hours.',
        occurrenceCount: morningCount,
        tags: ['Time', 'Morning'],
      ));
    }

    return results;
  }

  // Heuristic 2: Mood Recurrence
  List<BehaviorPattern> _analyzeMoodRecurrence(List<ReflectionEntry> entries) {
    final moodCounts = <String, int>{};

    for (var entry in entries) {
      final mood = entry.mood; 
      if (mood == 'Unspecified') continue;
      moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
    }

    final results = <BehaviorPattern>[];

    moodCounts.forEach((mood, count) {
      if (count >= _minThreshold) {
        results.add(BehaviorPattern(
          id: const Uuid().v4(),
          title: 'Noticing "$mood" frequently',
          description: 'This state appears in multiple recent entries.',
          occurrenceCount: count,
          tags: ['State', mood],
        ));
      }
    });

    return results;
  }

  // Heuristic 3: Context Recurrence
  List<BehaviorPattern> _analyzeContextClusters(List<ReflectionEntry> entries) {
    final contextCounts = <String, int>{};

    for (var entry in entries) {
      final ctx = entry.context;
      if (ctx == 'Unspecified') continue;
      contextCounts[ctx] = (contextCounts[ctx] ?? 0) + 1;
    }

    final results = <BehaviorPattern>[];

    contextCounts.forEach((ctx, count) {
      if (count >= _minThreshold) {
        results.add(BehaviorPattern(
          id: const Uuid().v4(),
          title: 'Noticing context: $ctx',
          description: 'Reflections often noted in this setting.',
          occurrenceCount: count,
          tags: ['Context', ctx],
        ));
      }
    });

    return results;
  }
}
