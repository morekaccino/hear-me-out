import 'recording_index.dart';

/// Persists the [RecordingIndex] separately from `ProgressState`.
///
/// `load` returns null when no index has been written. A corrupt or future
/// document throws [FormatException]; the recording service then adopts the
/// media it finds instead of deleting it.
abstract class RecordingIndexStore {
  Future<RecordingIndex?> load();

  Future<void> save(RecordingIndex index);

  Future<void> clear();
}

/// In-memory [RecordingIndexStore] for tests.
class MemoryRecordingIndexStore implements RecordingIndexStore {
  MemoryRecordingIndexStore([this.value]);

  RecordingIndex? value;
  int saveCount = 0;
  int clearCount = 0;

  @override
  Future<RecordingIndex?> load() async => value;

  @override
  Future<void> save(RecordingIndex index) async {
    value = index;
    saveCount++;
  }

  @override
  Future<void> clear() async {
    value = null;
    clearCount++;
  }
}
