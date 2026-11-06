import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/learning/onboarding_choices.dart';
import '../../core/learning/placement.dart';
import '../../core/storage/onboarding_store.dart';
import '../../shared/audio/sound_service.dart';
import '../../shared/navigation/duo_route.dart';
import '../../state/providers.dart';
import 'placement_flow_screen.dart';

/// Opens the skippable placement check.
///
/// The caller may pass the onboarding answers it already has. Otherwise the
/// onboarding store is read; a missing or unreadable store falls back to the
/// slow-reader starting point instead of blocking the check.
Future<PlacementRecord?> openPlacementFlow(
  BuildContext context,
  WidgetRef ref, {
  ReadingLevel? readingLevel,
  bool? hasGuitar,
  int? initialStage,
  bool startAtResult = false,
}) async {
  var level = readingLevel;
  var guitar = hasGuitar;
  if (level == null && guitar == null) {
    try {
      final choices = await ref.read(onboardingStoreProvider).load();
      level = choices?.readingLevel;
      guitar = choices?.hasGuitar;
    } catch (_) {
      // Optional context only.
    }
  }
  if (!context.mounted) return null;
  unawaited(ref.read(soundServiceProvider).play(Sfx.uiSelect));
  return Navigator.of(context).push<PlacementRecord>(
    duoLessonRoute(
      (_) => PlacementFlowScreen(
        readingLevel: level,
        hasGuitar: guitar,
        initialStage: initialStage,
        startAtResult: startAtResult,
      ),
    ),
  );
}
