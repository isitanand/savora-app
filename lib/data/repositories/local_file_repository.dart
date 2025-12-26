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
            // Hardening: On corruption or read error, default to empty.
            // Do not convert to technical error for user.
            debugPrint('Error reading data file: $e');
            _dataCache = {'entries': [], 'intents': []};
        }
      } else {
        // Create empty file
        await _persist();
      }
    } catch (e) {
      // Hardening: If finding directory fails, we are effectively stateless/in-memory only.
      debugPrint('Error initializing storage: $e');
    }
  }

  Future<void> _persist() async {
    if (_file == null) return;
    try {
      await _file!.writeAsString(json.encode(_dataCache));
    } catch (e) {
      // Hardening: Write failure shouldn't crash app.
      // In production, we might keep dirty state in memory.
      debugPrint('Error persisting data: $e');
    }
  }

  // --- Entries ---

  @override
  Future<void> saveEntry(ReflectionEntry entry) async {
    try {
      final List<dynamic> entriesJson = _dataCache['entries'] ?? [];
      final index = entriesJson.indexWhere((e) => e['id'] == entry.id);

      if (index != -1) {
        // Update existing
        entriesJson[index] = entry.toJson();
      } else {
        // Add new
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
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Newest first
    } catch (e) {
      debugPrint('Error getting entries: $e');
      return []; // Return silence, not error
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

  // --- Intents ---

  @override
  Future<void> saveIntent(MonthlyIntent intent) async {
    try {
      final List<dynamic> intentsJson = _dataCache['intents'] ?? [];
      
      // Remove existing intent for same month if exists
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

  // --- Hardening ---

  @override
  Future<void> deleteAll() async {
    try {
      // 1. Clear In-Memory
      _dataCache = {
        'entries': [],
        'intents': [],
      };
      
      // 2. Overwrite File (Empty)
      await _persist();
      
      // 3. Silence (No return value, no confirmation msg here)
    } catch (e) {
      debugPrint('Error deleting all data: $e');
    }
  }

  // --- Data Portability ---

  @override
  Future<String> exportJson() async {
    // Return the raw JSON string of the current cache
    return json.encode(_dataCache);
  }

  @override
  Future<void> importJson(String jsonString) async {
    try {
      final decoded = json.decode(jsonString);
      
      // Basic Validation
      if (decoded is Map<String, dynamic>) {
        // Ensure keys exist, else default to empty lists
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
      rethrow; // Pass error up for UI handling
    }
  }
}

RepositoryInterface createRepository() => LocalFileRepository();
