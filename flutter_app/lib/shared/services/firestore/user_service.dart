import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';

class UserService extends FirestoreService {
  UserService() : super('users');

  Future<void> initializeUser(String userId) async {
    final exists = await documentExists(userId);
    if (!exists) {
      await createDocument(userId, {
        'account_created': FieldValue.serverTimestamp(),
        'xp': 0,
        'level': 1,
        'current_league': 'bronze',
        'is_pro': false,
      });
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final doc = await getDocument(userId);
    if (!doc.exists) return null;
    return doc.data() as Map<String, dynamic>?;
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await updateDocument(userId, data);
  }
}

final userService = UserService();
