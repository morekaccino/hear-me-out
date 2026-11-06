import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../learning/onboarding_choices.dart';

abstract class OnboardingStore {
  Future<OnboardingChoices?> load();

  Future<void> save(OnboardingChoices choices);

  Future<void> clear();
}

/// Stores the three onboarding answers under their own key.
///
/// The choices are context for later placement work, not part of the progress
/// schema. Corrupt or future data is ignored so onboarding can always start.
class SharedPreferencesOnboardingStore implements OnboardingStore {
  static const storageKey = 'hear_me_out_onboarding_v1';
  static const currentSchemaVersion = 1;

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _instance async =>
      _prefs ??= await SharedPreferences.getInstance();

  @override
  Future<OnboardingChoices?> load() async {
    try {
      final prefs = await _instance;
      final raw = prefs.getString(storageKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final version = decoded['schemaVersion'];
      if (version is! num) return null;
      final value = version.toInt();
      if (value < 1 || value > currentSchemaVersion) return null;
      return OnboardingChoices.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(OnboardingChoices choices) async {
    final prefs = await _instance;
    await prefs.setString(
      storageKey,
      jsonEncode({'schemaVersion': currentSchemaVersion, ...choices.toJson()}),
    );
  }

  @override
  Future<void> clear() async {
    final prefs = await _instance;
    await prefs.remove(storageKey);
  }
}

final onboardingStoreProvider = Provider<OnboardingStore>(
  (ref) => SharedPreferencesOnboardingStore(),
);
