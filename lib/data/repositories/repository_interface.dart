import '../models/monthly_intent.dart';
import '../models/reflection_entry.dart';

abstract class RepositoryInterface {
  Future<void> init();
  
  // Reflection Entry Operations
  Future<void> saveEntry(ReflectionEntry entry);
  Future<List<ReflectionEntry>> getEntries();
  Future<void> deleteEntry(String id);

  // Monthly Intent Operations
  Future<void> saveIntent(MonthlyIntent intent);
  Future<MonthlyIntent?> getIntent(String monthYear);

  // Hardening / Reset
  Future<void> deleteAll();

  // Data Portability
  Future<String> exportJson();
  Future<void> importJson(String jsonString);
}
