import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../config/firebase_config.dart';
import '../services/firestore/user_service.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseConfig.auth.authStateChanges();
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).asData?.value;
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier() : super(const AsyncValue.loading());

  Future<void> signInAnonymously() async {
    state = const AsyncValue.loading();
    try {
      final result = await FirebaseConfig.auth.signInAnonymously();
      state = AsyncValue.data(result.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final result = await FirebaseConfig.auth.signInWithEmailAndPassword(
        email: email, password: password,
      );
      state = AsyncValue.data(result.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signUpWithEmail(String email, String password, String displayName) async {
    state = const AsyncValue.loading();
    try {
      final result = await FirebaseConfig.auth.createUserWithEmailAndPassword(
        email: email, password: password,
      );
      await result.user?.updateDisplayName(displayName);
      await userService.initializeUser(result.user!.uid);
      state = AsyncValue.data(result.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    await FirebaseConfig.auth.signOut();
    state = const AsyncValue.data(null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier();
});
