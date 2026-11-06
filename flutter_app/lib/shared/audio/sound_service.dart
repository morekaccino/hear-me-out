import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// The original Warm Mallet / Practice Bell sound family.
///
/// Keep the assets together; they share the same marimba, bell, woodblock, and
/// room-tail palette. Volume is set per cue so answer feedback stays prominent
/// without making UI taps noisy.
enum Sfx {
  uiTapPrimary('ui_tap_primary.wav', volume: 0.3),
  uiTapSecondary('ui_tap_secondary.wav', volume: 0.26),
  uiSelect('ui_select.wav', volume: 0.28),
  uiNavigate('ui_navigate.wav', volume: 0.22),
  uiToggleOn('ui_toggle_on.wav', volume: 0.3),
  uiToggleOff('ui_toggle_off.wav', volume: 0.28),
  uiLocked('ui_locked.wav', volume: 0.28),
  uiPage('ui_page.wav', volume: 0.16),
  lessonStart('lesson_start.wav', volume: 0.38),
  tunerOn('tuner_on.wav', volume: 0.28),
  tunerOff('tuner_off.wav', volume: 0.24),
  copySuccess('copy_success.wav', volume: 0.4),
  errorSoft('error_soft.wav', volume: 0.35),
  answerCorrect('answer_correct.wav', volume: 0.62),
  answerCorrectCombo('answer_correct_combo.wav', volume: 0.68),
  answerWrong('answer_wrong.wav', volume: 0.5),
  answerOctave('answer_octave.wav', volume: 0.52),
  lessonComplete('lesson_complete.wav', volume: 0.7),
  lessonPerfect('lesson_perfect.wav', volume: 0.74),
  lessonFailed('lesson_failed.wav', volume: 0.6),
  practiceComplete('practice_complete.wav', volume: 0.55),
  rewardStreak('reward_streak.wav', volume: 0.5),
  rewardStreakMilestone('reward_streak_milestone.wav', volume: 0.6),
  rewardWeeklyGoal('reward_weekly_goal.wav', volume: 0.55),
  rewardLevelUp('reward_level_up.wav', volume: 0.6),
  rewardUnlock('reward_unlock.wav', volume: 0.48),
  xpTick('xp_tick.wav', volume: 0.2);

  const Sfx(this.asset, {this.volume = 0.5});

  final String asset;
  final double volume;
}

abstract class SoundService {
  bool get enabled;
  set enabled(bool value);

  Future<void> preload();

  Future<void> play(Sfx sound);

  Future<void> playSequence(Iterable<Sfx> sounds);

  Future<void> dispose();
}

/// Plays bundled effects with a small pool per cue.
///
/// Core cues are preloaded at startup. Less common reward/error cues are
/// created lazily on first use so the app does not keep dozens of native players
/// alive on low-end phones.
class AudioPlayersSoundService implements SoundService {
  static const _preload = <Sfx>[
    Sfx.uiTapPrimary,
    Sfx.uiTapSecondary,
    Sfx.uiSelect,
    Sfx.uiToggleOn,
    Sfx.uiToggleOff,
    Sfx.uiNavigate,
    Sfx.uiLocked,
    Sfx.uiPage,
    Sfx.lessonStart,
    Sfx.tunerOn,
    Sfx.tunerOff,
    Sfx.answerCorrect,
    Sfx.answerCorrectCombo,
    Sfx.answerWrong,
    Sfx.answerOctave,
    Sfx.lessonComplete,
    Sfx.lessonPerfect,
    Sfx.lessonFailed,
    Sfx.practiceComplete,
    Sfx.rewardUnlock,
    Sfx.xpTick,
  ];

  final Map<Sfx, AudioPool> _pools = {};
  final Map<Sfx, Future<AudioPool?>> _creating = {};
  Future<void>? _preloading;
  bool _enabled = true;
  bool _audioContextConfigured = false;

  @override
  bool get enabled => _enabled;

  @override
  set enabled(bool value) => _enabled = value;

  @override
  Future<void> preload() {
    return _preloading ??= _preloadCore();
  }

  Future<void> _preloadCore() async {
    await _configureAudioContext();
    for (final sound in _preload) {
      await _poolFor(sound);
    }
  }

  Future<void> _configureAudioContext() async {
    if (_audioContextConfigured) return;
    _audioContextConfigured = true;
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.none,
          ),
          iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
        ),
      );
    } catch (error) {
      debugPrint('Could not configure sound audio context: $error');
    }
  }

  Future<AudioPool?> _poolFor(Sfx sound) async {
    final existing = _pools[sound];
    if (existing != null) return existing;
    final inFlight = _creating[sound];
    if (inFlight != null) return inFlight;
    final future = _createPool(sound);
    _creating[sound] = future;
    try {
      return await future;
    } finally {
      _creating.remove(sound);
    }
  }

  Future<AudioPool?> _createPool(Sfx sound) async {
    try {
      final pool = await AudioPool.createFromAsset(
        path: 'audio/${sound.asset}',
        minPlayers: 1,
        maxPlayers: 2,
        playerMode: PlayerMode.mediaPlayer,
      );
      _pools[sound] = pool;
      return pool;
    } catch (error) {
      debugPrint('Could not load sound ${sound.name}: $error');
      return null;
    }
  }

  @override
  Future<void> play(Sfx sound) async {
    if (!_enabled) return;
    await _configureAudioContext();
    final pool = await _poolFor(sound);
    if (pool == null) return;
    try {
      await pool.start(volume: sound.volume);
    } catch (error) {
      debugPrint('Could not play sound ${sound.name}: $error');
    }
  }

  @override
  Future<void> playSequence(Iterable<Sfx> sounds) async {
    for (final sound in sounds) {
      if (!_enabled) return;
      await play(sound);
      await Future<void>.delayed(const Duration(milliseconds: 520));
    }
  }

  @override
  Future<void> dispose() async {
    for (final pool in _pools.values) {
      await pool.dispose();
    }
    _pools.clear();
  }
}
