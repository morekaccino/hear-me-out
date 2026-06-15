import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

// Note: The LearningCard and SessionStats models need Isar annotations
// but since they're freezed models, we'll use a simpler approach with maps for now.
// This service abstracts the local storage layer.

class LocalStorageService {
  Isar? _isar;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    final dir = await getApplicationDocumentsDirectory();
    // Isar.open will be called when schemas are ready
    // For now, we set up the directory structure
    _isar = await Isar.open(
      [], // Schemas will be added as models are annotated with @collection
      directory: dir.path,
      name: 'hear_me_out',
    );
    _initialized = true;
  }

  Isar get isar {
    if (!_initialized || _isar == null) {
      throw StateError('LocalStorageService not initialized. Call initialize() first.');
    }
    return _isar!;
  }

  bool get isInitialized => _initialized;

  Future<void> clearAll() async {
    if (!_initialized || _isar == null) return;
    await _isar!.writeTxn(() async {
      await _isar!.clear();
    });
  }

  Future<void> close() async {
    if (!_initialized || _isar == null) return;
    await _isar!.close();
    _isar = null;
    _initialized = false;
  }
}

final localStorageService = LocalStorageService();
