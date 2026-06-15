import 'package:cloud_firestore/cloud_firestore.dart';

class LearningProgressService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _progressPath(String userId) => 'users/$userId/learningProgress/current';

  Future<void> saveProgress(String userId, Map<String, dynamic> progressData) async {
    progressData['updated_at'] = FieldValue.serverTimestamp();
    await _db.doc(_progressPath(userId)).set(progressData, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> loadProgress(String userId) async {
    final doc = await _db.doc(_progressPath(userId)).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  Future<bool> progressExists(String userId) async {
    final doc = await _db.doc(_progressPath(userId)).get();
    return doc.exists;
  }

  Future<void> resetProgress(String userId) async {
    await _db.doc(_progressPath(userId)).delete();
  }
}

final learningProgressService = LearningProgressService();
