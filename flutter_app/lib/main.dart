import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'config/firebase_config.dart';
import 'shared/services/local/local_storage_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase and Isar are native-only; skip on web for UI preview
  if (!kIsWeb) {
    try {
      await FirebaseConfig.initialize();
      await localStorageService.initialize();
    } catch (e) {
      debugPrint('Init error (non-fatal): $e');
    }
  }

  runApp(const HearMeOutApp());
}
