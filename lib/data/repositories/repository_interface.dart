import '../models/monthly_intent.dart';
import '../models/reflection_entry.dart';

abstract class RepositoryInterface {
  Future<void> init();
  
  
  Future<void> saveEntry(ReflectionEntry entry);
  Future<List<ReflectionEntry>> getEntries();
  Future<void> deleteEntry(String id);

  
  Future<void> saveIntent(MonthlyIntent intent);
  Future<MonthlyIntent?> getIntent(String monthYear);

  
  Future<void> deleteAll();

  
  Future<String> exportJson();
  Future<void> importJson(String jsonString);
}
