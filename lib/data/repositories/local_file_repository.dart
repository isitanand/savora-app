import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/monthly_intent.dart';
import '../models/reflection_entry.dart';
import 'repository_interface.dart';

class LocalFileRepository implements RepositoryInterface {
  static const String _fileName = 'core_vision_data.json';
  File? _file;
  Map<String, dynamic> _dataCache = {
    'entries': [],
    'intents': [],
  };

  @override
  Future<void> init() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _file = File('${directory.path}/$_fileName');

      if (await _file!.exists()) {
        try {
          final jsonString = await _file!.readAsString();
          if (jsonString.isNotEmpty) {
            _dataCache = json.decode(jsonString);
          }
        } catch (e) {
            debugPrint('Error reading data file: $e');
            _dataCache = {'entries': [], 'intents': []};
        }
      } else {
        await _persist();
      }
    } catch (e) {
      
      debugPrint('Error initializing storage: $e');
    }
  }

  Future<void> _persist() async {
    if (_file == null) return;
    try {
      await _file!.writeAsString(json.encode(_dataCache));
    } catch (e) {
      
      
      debugPrint('Error persisting data: $e');
    }
  }

  

  @override
  Future<void> saveEntry(ReflectionEntry entry) async {
    try {
      final List<dynamic> entriesJson = _dataCache['entries'] ?? [];
      final index = entriesJson.indexWhere((e) => e['id'] == entry.id);

      if (index != -1) {
        entriesJson[index] = entry.toJson();
      } else {
        entriesJson.add(entry.toJson());
      }
      
      _dataCache['entries'] = entriesJson;
      await _persist();
    } catch (e) {
      debugPrint('Error saving entry: $e');
    }
  }

  @override
  Future<List<ReflectionEntry>> getEntries() async {
    try {
      final List<dynamic> entriesJson = _dataCache['entries'] ?? [];
      return entriesJson
          .map((e) => ReflectionEntry.fromJson(e))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); 
    } catch (e) {
      debugPrint('Error getting entries: $e');
      return []; 
    }
  }

  @override
  Future<void> deleteEntry(String id) async {
    try {
      final List<dynamic> entriesJson = _dataCache['entries'] ?? [];
      entriesJson.removeWhere((e) => e['id'] == id);
      _dataCache['entries'] = entriesJson;
      await _persist();
    } catch (e) {
      debugPrint('Error deleting entry: $e');
    }
  }

  

  @override
  Future<void> saveIntent(MonthlyIntent intent) async {
    try {
      final List<dynamic> intentsJson = _dataCache['intents'] ?? [];
      
      
      intentsJson.removeWhere((e) => e['monthYear'] == intent.monthYear);
      
      intentsJson.add(intent.toJson());
      _dataCache['intents'] = intentsJson;
      await _persist();
    } catch (e) {
      debugPrint('Error saving intent: $e');
    }
  }

  @override
  Future<MonthlyIntent?> getIntent(String monthYear) async {
    try {
      final List<dynamic> intentsJson = _dataCache['intents'] ?? [];
      final intentData = intentsJson.firstWhere(
        (e) => e['monthYear'] == monthYear,
        orElse: () => null,
      );
      
      if (intentData != null) {
        return MonthlyIntent.fromJson(intentData);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting intent: $e');
      return null;
    }
  }

  

  @override
  Future<void> deleteAll() async {
    try {
      
      _dataCache = {
        'entries': [],
        'intents': [],
      };
      
      
      await _persist();
      
      
    } catch (e) {
      debugPrint('Error deleting all data: $e');
    }
  }

  

  @override
  Future<String> exportJson() async {
    
    return json.encode(_dataCache);
  }

  @override
  Future<void> importJson(String jsonString) async {
    try {
      final decoded = json.decode(jsonString);
      
      
      if (decoded is Map<String, dynamic>) {
        _dataCache = {
          'entries': decoded['entries'] ?? [],
          'intents': decoded['intents'] ?? [],
        };
        await _persist();
      } else {
        throw FormatException("Invalid JSON structure");
      }
    } catch (e) {
      debugPrint('Error importing data: $e');
      rethrow; 
    }
  }
}

RepositoryInterface createRepository() => LocalFileRepository();
