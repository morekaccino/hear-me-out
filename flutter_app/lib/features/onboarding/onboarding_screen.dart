import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/note_matcher.dart';
import '../../core/audio/pitch_source.dart';
import '../../core/learning/onboarding_choices.dart';
import '../../core/music/note.dart';
import '../../core/storage/onboarding_store.dart';
import '../../shared/audio/sound_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/motion.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/mascot.dart';
import '../../shared/widgets/page_frame.dart';
import '../../shared/widgets/progress_widgets.dart';
import '../../shared/widgets/tappable.dart';
import '../../state/app_controller.dart';
import '../../state/providers.dart';
import '../../state/retention_controller.dart';
import '../placement/placement_navigation.dart';
import 'onboarding_pieces.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with WidgetsBindingObserver {
  final _pageController = PageController();
  int _page = 0;
  bool? _hasGuitar;
  ReadingLevel? _readingLevel;
  String? _pieceId;
  bool _finishing = false;
  String? _playingPieceId;
  Timer? _previewTimer;
  int _previewGeneration = 0;

  PitchSource? _source;
  StreamSubscription<PitchFrame>? _subscription;
  PitchReading _reading = PitchReading.silent;
  bool _checkingMic = false;
  bool _micExpanded = false;
  int _micGeneration = 0;
  String? _micError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(
      ref.read(retentionControllerProvider.notifier).recordOnboardingStart(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _previewGeneration++;
    _previewTimer?.cancel();
    unawaited(_stopMic());
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      unawaited(_stopMic());
      if (_playingPieceId != null) unawaited(_stopPreview());
    }
  }

  Future<void> _stopMic() async {
    final generation = ++_micGeneration;
    await _subscription?.cancel();
    _subscription = null;
    final source = _source;
    _source = null;
    await source?.stop();
    await source?.dispose();
    if (mounted && generation == _micGeneration) {
      setState(() {
        _reading = PitchReading.silent;
        _checkingMic = false;
      });
    }
  }

  Future<void> _stopPreview() async {
    _previewGeneration++;
    _previewTimer?.cancel();
    _previewTimer = null;
    if (mounted && _playingPieceId != null) {
      setState(() => _playingPieceId = null);
    }
    try {
      await ref.read(audioEngineProvider).stop();
    } catch (_) {
      // Preview audio is optional.
    }
  }

  Future<void> _startMic() async {
    if (_checkingMic || _source != null) return;
    // Register the start before the preview stop can yield. Otherwise a skip
    // or a second tap during a slow stop cannot invalidate this start.
    final generation = ++_micGeneration;
    setState(() {
      _checkingMic = true;
      _micExpanded = true;
      _micError = null;
    });
    // The mic must never hear the synth preview. Stop it before the pitch
    // source is created, not merely when leaving the piece screen.
    await _stopPreview();
    if (!mounted || generation != _micGeneration) return;
    final source = ref.read(pitchSourceFactoryProvider)();
    bool started;
    try {
      started = await source.start();
    } catch (_) {
      started = false;
    }
    if (!mounted || generation != _micGeneration) {
      await source.dispose();
      return;
    }
    if (!started) {
      await source.dispose();
      if (!mounted || generation != _micGeneration) return;
      setState(() {
        _checkingMic = false;
        _micError = 'Microphone access was denied. You can still practice by naming notes.';
      });
      return;
    }
    _source = source;
    _subscription = source.frames.listen((frame) {
      if (!mounted || generation != _micGeneration) return;
      if (!frame.voiced) {
        setState(() => _reading = PitchReading.silent);
        return;
      }
      final midi = frequencyToMidi(frame.frequency);
      setState(() {
        _reading = PitchReading(
          frequency: frame.frequency,
          midi: midi,
          cents: centsFromMidi(midi),
          clarity: frame.clarity,
          note: Note.fromMidi(midi.round()),
          voiced: true,
        );
      });
    });
    if (mounted) setState(() => _checkingMic = false);
  }

  Future<void> _goTo(int page) async {
    if (!mounted || page == _page) return;
    if (_page == 0 && page > 0) await _stopMic();
    // Stop the synth unconditionally when leaving the piece screen. The
    // preview ID is display state and can be stale while playback is tailing.
    if (_page == 2) await _stopPreview();
    if (!mounted) return;
    if (!_pageController.hasClients) {
      setState(() => _page = page);
      return;
    }
    await _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _chooseGuitar(bool value) async {
    setState(() => _hasGuitar = value);
    await _goTo(1);
  }

  Future<void> _chooseReading(ReadingLevel level) async {
    setState(() => _readingLevel = level);
    await _goTo(2);
  }

  void _setRetentionOptIn(bool value) {
    unawaited(
      ref
          .read(soundServiceProvider)
          .play(value ? Sfx.uiToggleOn : Sfx.uiToggleOff),
    );
    final controller = ref.read(retentionControllerProvider.notifier);
    unawaited(controller.setOptIn(value));
    if (value) {
      // The consent switch is the first point a new install can reach, so the
      // onboarding funnel starts here. The event is deduplicated and dropped
      // when opt-in is off.
      unawaited(controller.recordOnboardingStart());
    }
  }

  void _selectPiece(String pieceId) {
    if (_pieceId == pieceId) return;
    unawaited(ref.read(soundServiceProvider).play(Sfx.uiSelect));
    setState(() => _pieceId = pieceId);
  }

  Future<void> _playPreview(OnboardingPiece piece) async {
    // The reverse guard: never let a preview start over a live mic check.
    if (_source != null || _checkingMic) {
      await _stopMic();
      if (!mounted) return;
    }
    await _stopPreview();
    if (!mounted) return;

    final generation = ++_previewGeneration;
    setState(() => _playingPieceId = piece.id);
    // `AudioEngine.play` completes when playback starts, not when the sound
    // ends. Keep the UI state for the actual motif length so the indicator
    // cannot clear early and the preview is still known to be active.
    _previewTimer = Timer(
      piece.preview.duration + const Duration(milliseconds: 400),
      () {
        if (!mounted || generation != _previewGeneration) return;
        _previewGeneration++;
        _previewTimer = null;
        setState(() => _playingPieceId = null);
      },
    );
    try {
      await ref.read(audioEngineProvider).play(piece.preview);
    } catch (_) {
      if (!mounted || generation != _previewGeneration) return;
      _previewGeneration++;
      _previewTimer?.cancel();
      _previewTimer = null;
      setState(() => _playingPieceId = null);
    }
  }

  Future<void> _finish() async {
    if (_finishing) return;
    final pieceId = _pieceId ?? onboardingPieces.first.id;
    setState(() => _finishing = true);
    await _stopMic();
    await _stopPreview();

    final choices = OnboardingChoices(
      hasGuitar: _hasGuitar,
      readingLevel: _readingLevel,
      firstPieceId: pieceId,
      completedAt: DateTime.now(),
    );
    try {
      await ref.read(onboardingStoreProvider).save(choices);
    } catch (_) {
      // The app can still start if the optional choices cannot be saved.
    }
    if (!mounted) return;
    final settings = ref
        .read(appControllerProvider)
        .requireValue
        .progress
        .settings;
    await ref.read(appControllerProvider.notifier).completeOnboarding(settings);
    if (mounted) setState(() => _finishing = false);
  }

  void _chooseLater() {
    setState(() => _pieceId = onboardingPieces.first.id);
    unawaited(_finish());
  }

  Future<void> _openPlacement() async {
    await _stopPreview();
    if (!mounted) return;
    await openPlacementFlow(
      context,
      ref,
      readingLevel: _readingLevel,
      hasGuitar: _hasGuitar,
    );
  }

  @override
  Widget build(BuildContext context) {
    final retention = ref.watch(retentionControllerProvider).asData?.value;
    return Scaffold(
      body: SafeArea(
        child: PageFrame(
          child: Column(
            children: [
              _ProgressHeader(
                page: _page,
                onBack: _page == 0 ? null : () => _goTo(_page - 1),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) => setState(() => _page = page),
                  children: [
                    _GuitarPage(
                      selected: _hasGuitar,
                      checkingMic: _checkingMic,
                      listening: _source != null,
                      micExpanded: _micExpanded,
                      reading: _reading,
                      micError: _micError,
                      retentionOptIn: retention?.optIn ?? false,
                      onChoose: _chooseGuitar,
                      onCheckMic: _startMic,
                      onStopMic: _stopMic,
                      onRetentionChanged: _setRetentionOptIn,
                    ),
                    _ReadingPage(
                      selected: _readingLevel,
                      onSelected: _chooseReading,
                    ),
                    _PiecePage(
                      selectedId: _pieceId,
                      playingId: _playingPieceId,
                      onSelected: _selectPiece,
                      onPreview: _playPreview,
                      onChooseLater: _chooseLater,
                      onPlacement: _openPlacement,
                    ),
                  ],
                ),
              ),
              if (_page == 2)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: DuoButton(
                    label: _finishing ? 'STARTING…' : 'START PLAYING',
                    onPressed: _pieceId == null || _finishing ? null : _finish,
                    icon: Icons.arrow_forward_rounded,
                    sound: Sfx.rewardUnlock,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.page, required this.onBack});

  final int page;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: onBack == null
                ? null
                : IconButton(
                    tooltip: 'Back',
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
          ),
          const SizedBox(width: 8),
          for (var index = 0; index < 3; index++) ...[
            if (index > 0) const SizedBox(width: 6),
            Expanded(
              child: LessonProgressBar(
                value: index <= page ? 1 : 0,
                height: 8,
                color: index <= page ? AppColors.green : AppColors.border,
              ),
            ),
          ],
          const SizedBox(width: 12),
          Text(
            '${page + 1}/3',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuitarPage extends StatelessWidget {
  const _GuitarPage({
    required this.selected,
    required this.checkingMic,
    required this.listening,
    required this.micExpanded,
    required this.reading,
    required this.micError,
    required this.retentionOptIn,
    required this.onChoose,
    required this.onCheckMic,
    required this.onStopMic,
    required this.onRetentionChanged,
  });

  final bool? selected;
  final bool checkingMic;
  final bool listening;
  final bool micExpanded;
  final PitchReading reading;
  final String? micError;
  final bool retentionOptIn;
  final ValueChanged<bool> onChoose;
  final VoidCallback onCheckMic;
  final VoidCallback onStopMic;
  final ValueChanged<bool> onRetentionChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        children: [
          const Mascot(size: 132),
          const SizedBox(height: 12),
          const Text(
            'Do you have your guitar?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'You can start now or look around first. Nothing is locked.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          DuoButton(
            label: 'YES, I HAVE IT',
            onPressed: () => onChoose(true),
            icon: Icons.music_note_rounded,
            sound: Sfx.uiSelect,
          ),
          const SizedBox(height: 10),
          OutlineDuoButton(
            label: 'NOT NOW',
            onPressed: () => onChoose(false),
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 24),
          Divider(color: AppColors.border),
          const SizedBox(height: 16),
          Text(
            'Microphone is optional',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Play exercises use the mic. Naming notes works without one.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          OutlineDuoButton(
            label: listening
                ? 'LISTENING…'
                : checkingMic
                ? 'STARTING…'
                : 'CHECK YOUR MIC',
            onPressed: listening || checkingMic ? null : onCheckMic,
            icon: Icons.mic_rounded,
            color: AppColors.blue,
          ),
          if (micExpanded) ...[
            const SizedBox(height: 12),
            _MicReadingCard(reading: reading, error: micError),
            if (listening)
              TextButton(
                onPressed: onStopMic,
                child: Text(
                  'Stop checking',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
          ],
          const SizedBox(height: 24),
          SectionCard(
            color: AppColors.blueSoft,
            borderColor: AppColors.blue.withValues(alpha: 0.35),
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.science_rounded,
                    size: 20,
                    color: AppColors.blueDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Optional beta usage log',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.blueDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Off by default. Local only: event names and times, '
                        'no audio, no free text, no account. Never uploaded. '
                        'Erase any time in Profile.',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          color: AppColors.blueDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  key: const ValueKey('onboarding-retention-switch'),
                  value: retentionOptIn,
                  activeThumbColor: AppColors.green,
                  onChanged: onRetentionChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MicReadingCard extends StatelessWidget {
  const _MicReadingCard({required this.reading, required this.error});

  final PitchReading reading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final writtenNote = reading.note?.transposed(12);
    return SectionCard(
      child: Column(
        children: [
          if (reading.voiced && writtenNote != null)
            Column(
              children: [
                Text(
                  writtenNote.display,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: AppColors.greenDark,
                  ),
                ),
                Text(
                  'Written pitch · ${reading.frequency.toStringAsFixed(1)} Hz',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mic_none_rounded,
                  size: 20,
                  color: AppColors.textLight,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Play any note to check the mic.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
              ],
            ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.redDark,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReadingPage extends StatelessWidget {
  const _ReadingPage({required this.selected, required this.onSelected});

  final ReadingLevel? selected;
  final ValueChanged<ReadingLevel> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        children: [
          const Mascot(size: 104, mood: MascotMood.thinking),
          const SizedBox(height: 12),
          const Text(
            'How well do you read?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'We will pick a starting point. You can change it later.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          _ReadingCard(
            title: 'I know the note names',
            explanation: 'Start with short reading drills and guided hints.',
            icon: Icons.music_note_rounded,
            selected: selected == ReadingLevel.noteNames,
            onTap: () => onSelected(ReadingLevel.noteNames),
          ),
          _ReadingCard(
            title: "I'm a slow reader",
            explanation: 'Start with note names and build speed step by step.',
            icon: Icons.menu_book_rounded,
            selected: selected == ReadingLevel.slowReader,
            onTap: () => onSelected(ReadingLevel.slowReader),
          ),
          _ReadingCard(
            title: "I'm comfortable reading",
            explanation: 'Start with full phrases and fewer hints.',
            icon: Icons.auto_stories_rounded,
            selected: selected == ReadingLevel.comfortable,
            onTap: () => onSelected(ReadingLevel.comfortable),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => onSelected(ReadingLevel.slowReader),
            child: Text(
              'Not sure',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.blueDark,
              ),
            ),
          ),
          Text(
            'We will start you as a slow reader.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({
    required this.title,
    required this.explanation,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String explanation;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        selected: selected,
        label: '$title. $explanation',
        excludeSemantics: true,
        child: DuoTappable(
          onTap: onTap,
          pressedScale: 0.98,
          child: AnimatedContainer(
            duration: DuoMotion.fast,
            padding: const EdgeInsets.all(DuoSpacing.md),
            decoration: BoxDecoration(
              color: selected ? AppColors.greenSoft : AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.green : AppColors.border,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.green : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: selected ? Colors.white : AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: DuoSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        explanation,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.green,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PiecePage extends StatelessWidget {
  const _PiecePage({
    required this.selectedId,
    required this.playingId,
    required this.onSelected,
    required this.onPreview,
    required this.onChooseLater,
    required this.onPlacement,
  });

  final String? selectedId;
  final String? playingId;
  final ValueChanged<String> onSelected;
  final ValueChanged<OnboardingPiece> onPreview;
  final VoidCallback onChooseLater;
  final VoidCallback onPlacement;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        children: [
          const Text(
            'Pick a first piece',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Hear a short preview, then choose where to begin. You can change pieces later.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          for (final piece in onboardingPieces)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PieceCard(
                piece: piece,
                selected: piece.id == selectedId,
                playing: piece.id == playingId,
                onSelect: () => onSelected(piece.id),
                onPreview: () => onPreview(piece),
              ),
            ),
          TextButton(
            onPressed: onChooseLater,
            child: Text(
              'Choose later',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.blueDark,
              ),
            ),
          ),
          TextButton(
            key: const ValueKey('onboarding-placement'),
            onPressed: onPlacement,
            style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
            child: Text(
              'Not sure where to start? A short check can place you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.blueDark,
              ),
            ),
          ),
          Text(
            'We will start you with Greensleeves.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PieceCard extends StatelessWidget {
  const _PieceCard({
    required this.piece,
    required this.selected,
    required this.playing,
    required this.onSelect,
    required this.onPreview,
  });

  final OnboardingPiece piece;
  final bool selected;
  final bool playing;
  final VoidCallback onSelect;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${piece.title}. ${piece.composer}. ${piece.stage}.',
      excludeSemantics: true,
      child: DuoTappable(
        onTap: onSelect,
        pressedScale: 0.99,
        child: AnimatedContainer(
          duration: DuoMotion.fast,
          padding: const EdgeInsets.all(DuoSpacing.md),
          decoration: BoxDecoration(
            color: selected ? AppColors.greenSoft : AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.green : AppColors.border,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          piece.title,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          piece.composer,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.green,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _PieceBadge(
                    label: piece.stage,
                    background: AppColors.blueSoft,
                    foreground: AppColors.blueDark,
                  ),
                  _PieceBadge(
                    label: 'SYNTH PREVIEW',
                    background: AppColors.purpleSoft,
                    foreground: AppColors.purpleDark,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                piece.description,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: _PreviewButton(
                  key: ValueKey('preview-${piece.id}'),
                  playing: playing,
                  onTap: onPreview,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PieceBadge extends StatelessWidget {
  const _PieceBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          color: foreground,
        ),
      ),
    );
  }
}

class _PreviewButton extends StatelessWidget {
  const _PreviewButton({super.key, required this.playing, required this.onTap});

  final bool playing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DuoTappable(
      onTap: onTap,
      pressedScale: 0.95,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: playing ? AppColors.blueSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderStrong, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              playing ? Icons.graphic_eq_rounded : Icons.play_arrow_rounded,
              size: 20,
              color: AppColors.blueDark,
            ),
            const SizedBox(width: 6),
            Text(
              playing ? 'PLAYING…' : 'PREVIEW',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.blueDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
