import 'repositories/local_file_repository.dart';
import 'repositories/repository_interface.dart';

class DataService {
  // Singleton Pattern
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  late final RepositoryInterface _repository;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    // Choose implementation here (Dependency Injection lite)
    _repository = LocalFileRepository();
    await _repository.init();
    
    _isInitialized = true;
    print("DataService: Initialized.");
  }

  RepositoryInterface get repository {
    if (!_isInitialized) {
      throw Exception("DataService not initialized. Call init() first.");
    }
    return _repository;
  }
}
