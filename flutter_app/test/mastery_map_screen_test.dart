import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/app.dart';
import 'package:hear_me_out/content/pieces/phrase_objectives.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/media/media_store.dart';
import 'package:hear_me_out/core/media/recording_index.dart';
import 'package:hear_me_out/core/media/recording_index_store.dart';
import 'package:hear_me_out/core/media/recording_service.dart';
import 'package:hear_me_out/core/music/note.dart';
import 'package:hear_me_out/core/music/note_event.dart';
import 'package:hear_me_out/core/music/phrase.dart';
import 'package:hear_me_out/core/music/piece.dart';
import 'package:hear_me_out/core/music/score.dart';
import 'package:hear_me_out/core/storage/onboarding_store.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';
import 'package:hear_me_out/features/mastery/mastery_map_screen.dart';
import 'package:hear_me_out/shared/theme/app_theme.dart';
import 'package:hear_me_out/state/providers.dart';

import 'support/fakes.dart';

const _events = <NoteEvent>[
  NoteEvent(
    startBeat: 0,
    durationBeats: 1,
    kind: NoteEventKind.note,
    writtenNote: Note('G', 3),
    soundingMidi: 43,
    string: 6,
    fret: 3,
  ),
  NoteEvent(
    startBeat: 1,
    durationBeats: 1,
    kind: NoteEventKind.note,
    writtenNote: Note('A', 3),
    soundingMidi: 45,
    string: 5,
    fret: 0,
  ),
];

final _piece = Piece(
  id: 'study',
  title: 'Original Study',
  composer: 'Hear Me Out',
  license: 'original',
  tuning: Tuning.standard,
  timeSignature: const TimeSignature(4, 4),
  key: 'G major',
);

Phrase _phrase({int difficulty = 1}) => Phrase(
  id: 'study-p1',
  bars: 1,
  timeSignature: const TimeSignature(4, 4),
  events: _events,
  targetTempoBpm: 72,
  title: 'Rising line',
  skills: const <String>['note-reading.first-position'],
  difficulty: difficulty,
);

PhraseObjectiveRegistry _registry() =>
    PhraseObjectiveRegistry()
      ..registerScore(Score(piece: _piece, phrases: <Phrase>[_phrase()]));

PhraseProgress _phraseProgress({int dayCount = 3}) {
  final progress = PhraseProgress(phraseId: 'study-p1');
  final days = [
    DateTime(2026, 1, 1, 10),
    DateTime(2026, 1, 5, 10),
    DateTime(2026, 1, 12, 10),
  ];
  for (var index = 0; index < dayCount; index++) {
    progress.recordAttempt(
      PhraseAttempt(
        phraseId: 'study-p1',
        outcome: AttemptOutcome.correct,
        now: days[index],
        accuracy: 1,
        tempoBpm: 72,
        targetTempoBpm: 72,
      ),
    );
  }
  return progress;
}

Uint8List _takeBytes() =>
    pcm16Bytes(<double>[for (var index = 0; index < 800; index++) 0.2]);

class _Harness {
  _Harness({required this.progress, this.emptyRegistry = false}) {
    service = RecordingService(
      store: media,
      indexStore: indexStore,
      exporter: FakeRecordingExporter(),
      clock: () => DateTime.utc(2026, 2, 1, 12),
      recorderFactory: () => throw StateError('No recording in this test'),
    );
  }

  final ProgressState progress;
  final bool emptyRegistry;
  final MemoryMediaStore media = MemoryMediaStore();
  final MemoryRecordingIndexStore indexStore = MemoryRecordingIndexStore();
  final FakeTakePlayer player = FakeTakePlayer();
  late final RecordingService service;

  Future<void> seedTake({String id = 'latest-take'}) async {
    final bytes = _takeBytes();
    final ref = await media.put(
      bytes,
      mimeType: RecordingService.wavMimeType,
      id: id,
      pieceId: 'study',
      phraseId: 'study-p1',
      durationMs: 2000,
    );
    indexStore.value = (indexStore.value ?? RecordingIndex.empty).add(
      RecordingTake.fromMediaRef(ref),
    );
  }

  Widget buildScreen({bool useApp = false}) {
    final overrides = [
      progressStoreProvider.overrideWithValue(MemoryProgressStore(progress)),
      onboardingStoreProvider.overrideWithValue(FakeOnboardingStore()),
      phraseRegistryProvider.overrideWithValue(
        emptyRegistry ? PhraseObjectiveRegistry() : _registry(),
      ),
      recordingServiceProvider.overrideWithValue(AsyncData(service)),
      takePlayerProvider.overrideWithValue(player),
      soundServiceProvider.overrideWithValue(FakeSoundService()),
      audioEngineProvider.overrideWithValue(FakeAudioEngine()),
      pitchSourceFactoryProvider.overrideWithValue(
        FakePitchSourceFactory(permission: false).call,
      ),
    ];
    return ProviderScope(
      overrides: overrides,
      child: useApp
          ? const HearMeOutApp()
          : MaterialApp(theme: AppTheme.light, home: const MasteryMapScreen()),
    );
  }
}

void _useSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('empty map shows honest empty states at 390x844', (tester) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness(
      progress: ProgressState.fresh(),
      emptyRegistry: true,
    );
    await tester.pumpWidget(harness.buildScreen());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('mastery-map-screen')), findsOneWidget);
    expect(find.text('What you can play'), findsOneWidget);
    expect(
      find.text(
        'No performance-mastered phrases yet. Play a phrase at tempo on three '
        'separate days.',
      ),
      findsOneWidget,
    );
    expect(find.text('Nothing due or fragile right now.'), findsOneWidget);
    expect(find.textContaining('No reading skills yet'), findsOneWidget);
    expect(
      find.text('Nothing due right now. Play a phrase when one is available.'),
      findsOneWidget,
    );
    expect(find.text('CAN PLAY'), findsNothing);
    expect(find.textContaining('%'), findsNothing);
    expect(find.textContaining('240 lessons'), findsNothing);
    expect(tester.takeException(), isNull);
    await harness.service.dispose();
  });

  testWidgets('fits a 1200px viewport without overflow', (tester) async {
    _useSize(tester, const Size(1200, 900));
    final harness = _Harness(
      progress: ProgressState.fresh(),
      emptyRegistry: true,
    );
    await tester.pumpWidget(harness.buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('What you can play'), findsOneWidget);
    expect(find.text('Reading'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await harness.service.dispose();
  });

  testWidgets('a mastered fixture earns the badge and plays its take', (
    tester,
  ) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness(
      progress: ProgressState(phraseProgress: {'study-p1': _phraseProgress()}),
    );
    await harness.seedTake();
    await tester.pumpWidget(harness.buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('CAN PLAY'), findsOneWidget);
    expect(find.text('Original Study'), findsOneWidget);
    expect(find.text('Rising line'), findsOneWidget);
    expect(find.textContaining('72 BPM'), findsOneWidget);
    expect(find.textContaining('12 Jan 2026'), findsOneWidget);
    expect(find.byKey(const ValueKey('mastery-play-study-p1')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('mastery-play-study-p1')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(harness.player.played, hasLength(1));
    expect(harness.player.played.single, isNotEmpty);
    expect(tester.takeException(), isNull);
    await harness.service.dispose();
  });

  testWidgets('a two-day fixture is not a can-play badge', (tester) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness(
      progress: ProgressState(
        phraseProgress: {'study-p1': _phraseProgress(dayCount: 2)},
      ),
    );
    await tester.pumpWidget(harness.buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('CAN PLAY'), findsNothing);
    expect(find.byKey(const ValueKey('mastery-play-study-p1')), findsNothing);
    expect(
      find.textContaining('No performance-mastered phrases yet'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await harness.service.dispose();
  });

  testWidgets('Profile opens the mastery map and shows only earned badges', (
    tester,
  ) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness(
      progress: ProgressState(
        settings: const AppSettings(onboardingComplete: true),
        phraseProgress: {'study-p1': _phraseProgress()},
      ),
    );
    await harness.seedTake();
    await tester.pumpWidget(harness.buildScreen(useApp: true));
    await tester.pumpAndSettle();

    // Leave onboarding on the normal path, then open Profile.
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('mastery-map-card')), findsOneWidget);
    expect(find.text('Can play'), findsOneWidget);

    await tester.tap(find.text('OPEN MASTERY MAP'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('mastery-map-screen')), findsOneWidget);
    expect(find.text('CAN PLAY'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await harness.service.dispose();
  });
}
