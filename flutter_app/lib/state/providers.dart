import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../content/pieces/phrase_objectives.dart';
import '../core/audio/phrase_recorder.dart';
import '../core/audio/pitch_source.dart';
import '../core/media/backup_exclusion.dart';
import '../core/media/media_store.dart';
import '../core/media/media_store_factory.dart';
import '../core/media/recording_exporter.dart';
import '../core/media/recording_exporter_factory.dart';
import '../core/media/recording_index_store.dart';
import '../core/media/recording_index.dart';
import '../core/media/recording_service.dart';
import '../core/notifications/reminder_scheduler.dart';
import '../core/notifications/reminder_scheduler_factory.dart';
import '../core/storage/recording_index_store.dart';
import '../shared/audio/audio_engine.dart';
import '../shared/audio/sound_service.dart';
import '../shared/audio/take_player.dart';

typedef PitchSourceFactory = PitchSource Function();

final pitchSourceFactoryProvider = Provider<PitchSourceFactory>(
  (ref) => RecordPitchSource.new,
);

/// Builds a phrase recorder. Tests inject a fake capture or fake recorder.
///
/// The phrase player owns at most one recorder at a time. Do not start one
/// while a tuner or lesson [PitchSource] is live; the platform recorder is a
/// single shared resource.
typedef PhraseRecorderFactory = PhraseRecorder Function();

final phraseRecorderFactoryProvider = Provider<PhraseRecorderFactory>(
  (ref) =>
      () => PhraseRecorder(capture: createPlatformPcmCapture()),
);

/// Single clock seam for session timing. Tests override it to advance a lesson
/// without waiting in real time.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// The one phrase-content registry shared by Today, practice, and the mastery
/// map. It is empty until a content loader registers parsed scores; there is
/// no second registry.
final phraseRegistryProvider = Provider<PhraseObjectiveRegistry>(
  (ref) => phraseObjectiveRegistry,
);

/// Time to ignore at the start of a mic exercise so the previous note's tail
/// cannot trigger an answer. Tests set this to zero.
final lessonGraceProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 250),
);

/// Platform service that keeps the IO media directory out of cloud backup.
///
/// Android handles exclusion with manifest backup rules, so this is a no-op
/// there. iOS sets `NSURLIsExcludedFromBackupKey` through a method channel.
/// Tests override this provider with a fake.
final mediaBackupExclusionProvider = Provider<MediaBackupExclusion>(
  (ref) => createMediaBackupExclusion(),
);

/// Builds the recording directory beneath [supportPath].
///
/// The last segment is [mediaDirectoryName]. Android backup rules and the iOS
/// backup exclusion depend on that name, so keep all three in sync.
String mediaDirectoryFor(String supportPath) =>
    '$supportPath/$mediaDirectoryName';

/// Absolute directory for recordings on IO platforms, or an empty string on
/// web.
///
/// Tests override this provider to avoid `path_provider` and to point at a
/// temporary directory.
final mediaDirectoryProvider = FutureProvider<String>((ref) async {
  if (kIsWeb) return '';
  final supportDirectory = await getApplicationSupportDirectory();
  return mediaDirectoryFor(supportDirectory.path);
});

/// Result of the backup-exclusion attempt for the recording directory.
///
/// The profile privacy card watches this value so it never claims exclusion
/// when the platform did not confirm it. T4.2's recording flow must read it
/// before presenting a take as private. A failed result is reported, but it
/// does not throw: the caller can still decide whether to record.
final mediaBackupStatusProvider = FutureProvider<BackupExclusionResult>((
  ref,
) async {
  if (kIsWeb) {
    return const BackupExclusionResult.notRequired(
      'The web build has no app-managed backup exclusion.',
    );
  }

  try {
    final directory = await ref.watch(mediaDirectoryProvider.future);
    return await _excludeMediaDirectory(
      ref.watch(mediaBackupExclusionProvider),
      directory,
    );
  } catch (error) {
    return BackupExclusionResult.failed(error);
  }
});

/// Local recording store.
///
/// On IO the store lives under the application support directory. Before the
/// store is created, [mediaBackupStatusProvider] asks the platform to keep the
/// directory out of cloud backup. A failed exclusion is logged and does not
/// block storage, but the app must not claim the directory is excluded. On web
/// the store is IndexedDB. Tests override this provider with `MemoryMediaStore`;
/// nothing here starts a recorder or touches the microphone.
final mediaStoreProvider = FutureProvider<MediaStore>((ref) async {
  if (kIsWeb) {
    return createMediaStore();
  }

  final directory = await ref.watch(mediaDirectoryProvider.future);
  final exclusion = await ref.watch(mediaBackupStatusProvider.future);
  if (exclusion.status == BackupExclusionStatus.failed) {
    debugPrint(
      'Hear Me Out: media backup exclusion failed; recordings may be backed '
      'up. $exclusion',
    );
  }

  return createMediaStore(directory: directory);
});

Future<BackupExclusionResult> _excludeMediaDirectory(
  MediaBackupExclusion exclusion,
  String directory,
) async {
  try {
    return await exclusion.excludeFromBackup(directory);
  } catch (error) {
    return BackupExclusionResult.failed(error);
  }
}

/// Absolute directory where explicit take exports are written on IO, or an
/// empty string on web. The browser owns downloads on web.
final exportsDirectoryProvider = FutureProvider<String>((ref) async {
  if (kIsWeb) return '';
  final supportDirectory = await getApplicationSupportDirectory();
  return '${supportDirectory.path}/exports';
});

/// Persists the take manifest separately from `ProgressState`.
final recordingIndexStoreProvider = Provider<RecordingIndexStore>(
  (ref) => SharedPreferencesRecordingIndexStore(),
);

/// Read-only takes for the Quests recap.
///
/// It reads the recording index directly, newest first. It deliberately does
/// not watch `recordingControllerProvider`: that controller owns the
/// microphone and is auto-disposed with the recordings route. Keeping it alive
/// from a tab would break the mic lifecycle rule. The index is the same durable
/// data the controller lists.
final recordingRecapTakesProvider =
    FutureProvider.autoDispose<List<RecordingTake>>((ref) async {
      final index = await ref.watch(recordingIndexStoreProvider).load();
      return List<RecordingTake>.unmodifiable(
        index?.takes.reversed.toList() ?? const <RecordingTake>[],
      );
    });

/// Copies explicit exports out of the app. IO writes under `exports/`; web
/// downloads through the browser. Tests override it with a fake.
final recordingExporterProvider = FutureProvider<RecordingExporter>((ref) async {
  final exportsDirectory = await ref.watch(exportsDirectoryProvider.future);
  return createRecordingExporter(exportsDirectory: exportsDirectory);
});

/// Builds the bounded local recording service.
///
/// The service never starts the microphone by itself. It is constructed only
/// when the recordings screen or a test reads this provider.
final recordingServiceProvider = FutureProvider<RecordingService>((ref) async {
  final store = await ref.watch(mediaStoreProvider.future);
  final exporter = await ref.watch(recordingExporterProvider.future);
  final service = RecordingService(
    store: store,
    indexStore: ref.watch(recordingIndexStoreProvider),
    exporter: exporter,
    clock: ref.watch(clockProvider),
    recorderFactory: ref.watch(phraseRecorderFactoryProvider),
  );
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});

/// Plays WAV takes from local storage. Overridden in widget tests.
final takePlayerProvider = Provider<TakePlayer>((ref) {
  final player = AudioPlayersTakePlayer();
  ref.onDispose(() {
    unawaited(player.dispose());
  });
  return player;
});

/// Opt-in local practice reminders.
///
/// Web resolves to a no-op scheduler, so the settings screen can say reminders
/// are unavailable instead of pretending. Tests override this provider with a
/// fake and assert the exact schedule request.
final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) {
  final scheduler = createReminderScheduler();
  ref.onDispose(() {
    unawaited(scheduler.dispose());
  });
  return scheduler;
});

final soundServiceProvider = Provider<SoundService>((ref) {
  final service = AudioPlayersSoundService();
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});

final audioEngineProvider = Provider<AudioEngine>((ref) {
  final engine = AudioPlayersSpecEngine();
  ref.onDispose(() {
    unawaited(engine.dispose());
  });
  return engine;
});
