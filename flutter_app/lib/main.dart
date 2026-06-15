import 'package:flutter/material.dart';
import 'config/firebase_config.dart';
import 'shared/services/local/local_storage_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initialize();
  await localStorageService.initialize();
  runApp(const HearMeOutApp());
}
