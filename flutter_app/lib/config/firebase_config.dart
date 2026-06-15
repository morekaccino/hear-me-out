import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseConfig {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyDd-V29qlWfwQVfxdgX2B97smMX-34EA8A',
        authDomain: 'hearmeout-1995.firebaseapp.com',
        projectId: 'hearmeout-1995',
        storageBucket: 'hearmeout-1995.firebasestorage.app',
        messagingSenderId: '322488809981',
        appId: '1:322488809981:web:a4f79759a796f18ed30194',
      ),
    );
  }

  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseAuth get auth => FirebaseAuth.instance;
}
