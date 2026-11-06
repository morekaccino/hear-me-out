import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/audio/phrase_prompt.dart';
import 'package:hear_me_out/core/audio/phrase_recorder.dart';
import 'package:hear_me_out/core/audio/pitch_source.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';
import 'package:hear_me_out/features/phrase/phrase_player_screen.dart';
import 'package:hear_me_out/shared/theme/app_theme.dart';
import 'package:hear_me_out/state/providers.dart';

import 'support/audio_fixtures.dart';
import 'support/fakes.dart';
import 'support/phrase_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PhrasePlayPrompt prompt;
  late List<double> cleanTake;

  setUpAll(() {
    final score = loadCorpusScore('foundation/ode-to-joy.json');
    prompt = PhrasePlayPrompt(phrase: score.phrases.first);
    cleanTake = renderPromptTake(prompt, sampleRate: 48000);
  });

  Widget buildScreen({
    required MemoryProgressStore store,
    bool headphonesConfirmed = false,
    bool clockVerified = false,
    int? contentVersion,
    FakeAudioEngine? engine,
    FakePcmCapture? capture,
    PhraseRecorder Function()? recorderFactory,
  }) {
    final recorderCapture =
        capture ??
        FakePcmCapture(
          chunks: [pcm16Bytes(cleanTake)],
          config: const PcmCaptureConfig(sampleRate: 48000, channels: 1),
        );
    return ProviderScope(
      overrides: [
        progressStoreProvider.overrideWithValue(store),
        soundServiceProvider.overrideWithValue(FakeSoundService()),
        audioEngineProvider.overrideWithValue(engine ?? FakeAudioEngine()),
        phraseRecorderFactoryProvider.overrideWithValue(
          recorderFactory ?? () => PhraseRecorder(capture: recorderCapture),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: PhrasePlayerScreen(
          phrase: prompt.phrase,
          contentVersion: contentVersion,
          headphonesConfirmed: headphonesConfirmed,
          clockVerified: clockVerified,
        ),
      ),
    );
  }

  MemoryProgressStore freshStore() => MemoryProgressStore(
    ProgressState.fresh(settings: const AppSettings(onboardingComplete: true)),
  );

  void useSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> pumpPastCountIn(WidgetTester tester) async {
    for (var beat = 0; beat < 4; beat++) {
      await tester.pump(const Duration(milliseconds: 834));
    }
  }

  Future<void> recordAndStop(WidgetTester tester) async {
    await tester.tap(find.text('RECORD'));
    await tester.pump();
    await tester.pump();
    await pumpPastCountIn(tester);
    await tester.tap(find.text('STOP'));
    await tester.pumpAndSettle();
    for (var index = 0; index < 20; index++) {
      if (find.text('TRY AGAIN').evaluate().isNotEmpty) break;
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
  }

  testWidgets('fits 390x844 and shows no game chrome', (tester) async {
    useSize(tester, const Size(390, 844));
    final store = freshStore();
    await tester.pumpWidget(buildScreen(store: store));
    await tester.pumpAndSettle();

    expect(find.text('Theme, first half'), findsOneWidget);
    expect(find.textContaining('72 BPM'), findsOneWidget);
    expect(find.text('BAR 1'), findsOneWidget);
    expect(find.text('BAR 2'), findsOneWidget);
    expect(find.text('F♯5'), findsWidgets);
    expect(find.text('PREVIEW'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    expect(find.textContaining('XP'), findsNothing);
    expect(find.textContaining('Streak'), findsNothing);
    expect(find.textContaining('gems'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fits a 1200px viewport without overflow', (tester) async {
    useSize(tester, const Size(1200, 900));
    final store = freshStore();
    await tester.pumpWidget(buildScreen(store: store));
    await tester.pumpAndSettle();

    expect(find.text('Theme, first half'), findsOneWidget);
    expect(find.text('RECORD'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('play, count-in, record, stop, correction, and retry', (
    tester,
  ) async {
    useSize(tester, const Size(390, 844));
    final store = freshStore();
    final engine = FakeAudioEngine();
    await tester.pumpWidget(buildScreen(store: store, engine: engine));
    await tester.pumpAndSettle();

    await tester.tap(find.text('PLAY'));
    await tester.pump();
    expect(engine.played, hasLength(1));
    expect(engine.played.single.events, isNotEmpty);

    // Confirm wired headphones through the gate card, then record.
    await tester.tap(find.text('Wired headphones connected'));
    await tester.pump();
    expect(find.text('Scored take ready'), findsOneWidget);

    await tester.tap(find.text('RECORD'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Count-in: 4'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 834));
    expect(find.text('Count-in: 3'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 834));
    expect(find.text('Count-in: 2'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 834));
    expect(find.text('Count-in: 1'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 834));
    expect(find.text('Recording — play the phrase.'), findsOneWidget);

    await tester.tap(find.text('STOP'));
    await tester.pumpAndSettle();
    for (var index = 0; index < 20; index++) {
      if (find.text('Clean take').evaluate().isNotEmpty) break;
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Clean take'), findsOneWidget);
    expect(
      find.text('Clean take. Keep this tempo and add the next bar.'),
      findsOneWidget,
    );
    expect(find.text('Saved to phrase progress.'), findsOneWidget);
    final saved = store.value!.phraseProgressFor('ode-to-joy-p1');
    expect(saved, isNotNull);
    expect(saved!.correct, 1);
    expect(saved.reps, 1);
    expect(saved.contentVersion, prompt.phrase.contentVersion);

    // Changing the gate after the take must not rewrite what happened to it.
    await tester.ensureVisible(find.text('Wired headphones connected'));
    await tester.tap(find.text('Wired headphones connected'));
    await tester.pump();
    expect(find.text('Saved to phrase progress.'), findsOneWidget);
    expect(find.text('Practice only — this take was not saved.'), findsNothing);

    await tester.ensureVisible(find.text('TRY AGAIN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TRY AGAIN'));
    await tester.pumpAndSettle();
    expect(
      find.text('Clean take. Keep this tempo and add the next bar.'),
      findsNothing,
    );
    expect(find.text('Listen once, then record a take.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unverified take is practice only and saves nothing', (
    tester,
  ) async {
    useSize(tester, const Size(390, 844));
    final store = freshStore();
    await tester.pumpWidget(buildScreen(store: store));
    await tester.pumpAndSettle();

    expect(find.textContaining('practice only'), findsOneWidget);

    await tester.tap(find.text('RECORD'));
    await tester.pump();
    await tester.pump();
    await pumpPastCountIn(tester);
    expect(find.text('Recording — play the phrase.'), findsOneWidget);

    await tester.tap(find.text('STOP'));
    await tester.pumpAndSettle();

    expect(
      find.text('Practice only — this take was not saved.'),
      findsOneWidget,
    );
    expect(store.value!.phraseProgressFor('ode-to-joy-p1'), isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an indeterminate gate-open take is not saved', (tester) async {
    useSize(tester, const Size(390, 844));
    final store = freshStore();
    final silence = FakePcmCapture(
      chunks: [pcm16Bytes(silentTake(48000, 12))],
      config: const PcmCaptureConfig(sampleRate: 48000, channels: 1),
    );
    await tester.pumpWidget(
      buildScreen(store: store, capture: silence, headphonesConfirmed: true),
    );
    await tester.pumpAndSettle();
    expect(find.text('Scored take ready'), findsOneWidget);

    await recordAndStop(tester);

    expect(find.text('Let’s try that again'), findsOneWidget);
    expect(
      find.text('Could not hear the whole phrase — try again.'),
      findsOneWidget,
    );
    expect(
      find.text('Not saved. Incomplete takes never update progress.'),
      findsOneWidget,
    );
    expect(find.textContaining('wrong'), findsNothing);
    expect(store.value!.phraseProgressFor('ode-to-joy-p1'), isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses the saved intonation tolerance', (tester) async {
    useSize(tester, const Size(390, 844));
    final store = MemoryProgressStore(
      ProgressState.fresh(
        settings: const AppSettings(
          onboardingComplete: true,
          toleranceCents: 50,
        ),
      ),
    );
    final take = renderPromptTake(prompt, sampleRate: 48000, cents: 40);
    final capture = FakePcmCapture(
      chunks: [pcm16Bytes(take)],
      config: const PcmCaptureConfig(sampleRate: 48000, channels: 1),
    );
    await tester.pumpWidget(
      buildScreen(store: store, headphonesConfirmed: true, capture: capture),
    );
    await tester.pumpAndSettle();

    await recordAndStop(tester);

    // A 40-cent take is in tune at the saved 50-cent tolerance, so the
    // correction is the positive next step rather than "center each note".
    expect(
      find.text('Clean take. Keep this tempo and add the next bar.'),
      findsOneWidget,
    );
    expect(
      find.text('Clean take. Keep this tempo and center each note.'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a verified clock allows a saved take', (tester) async {
    useSize(tester, const Size(390, 844));
    final store = freshStore();
    await tester.pumpWidget(
      buildScreen(store: store, clockVerified: true, contentVersion: 3),
    );
    await tester.pumpAndSettle();

    expect(find.text('Scored take ready'), findsOneWidget);
    expect(find.text('Device clock verified'), findsOneWidget);

    await recordAndStop(tester);

    expect(find.text('Saved to phrase progress.'), findsOneWidget);
    final saved = store.value!.phraseProgressFor('ode-to-joy-p1');
    expect(saved, isNotNull);
    expect(saved!.contentVersion, 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed recorder factory clears STARTING', (tester) async {
    useSize(tester, const Size(390, 844));
    final store = freshStore();
    await tester.pumpWidget(
      buildScreen(
        store: store,
        recorderFactory: () => throw StateError('factory failed'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('RECORD'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Could not start the microphone.'), findsOneWidget);
    expect(find.text('RECORD'), findsOneWidget);
    expect(find.text('STARTING'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a missing microphone shows calm recovery copy', (tester) async {
    useSize(tester, const Size(390, 844));
    final store = freshStore();
    final capture = FakePcmCapture(permission: false);
    await tester.pumpWidget(buildScreen(store: store, capture: capture));
    await tester.pumpAndSettle();

    await tester.tap(find.text('RECORD'));
    await tester.pump();
    await tester.pump();

    expect(
      find.text(
        'Microphone unavailable. Check permissions, or use Play to hear the phrase.',
      ),
      findsOneWidget,
    );
    expect(find.text('RECORD'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
