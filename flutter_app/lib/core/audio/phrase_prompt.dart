import '../music/guitar.dart';
import '../music/note.dart';
import '../music/phrase.dart';
import '../music/sound_spec.dart';
import 'alignment.dart';
import 'phrase_scorer.dart';

/// How the player should render the count-in and bar clicks.
///
/// The default is visual-only. An audible click is recorded by the phone
/// microphone on a speaker take and the scorer would count it as an attack, so
/// audible click is only safe with wired headphones or a verified clock.
enum PhraseClickMode {
  /// No click. The learner starts from the first note.
  silent,

  /// A visible count-in with no sound.
  visualCountIn,

  /// An audible count-in, allowed only behind the scored-take gate.
  audibleCountIn,
}

/// Small value object describing the backing a phrase player may request.
///
/// It deliberately holds no audio bytes. `lib/core` must stay platform-free.
class PhraseBackingSpec {
  const PhraseBackingSpec({
    this.clickMode = PhraseClickMode.visualCountIn,
    this.accentFirstBeat = true,
  });

  final PhraseClickMode clickMode;

  /// Accent beat one so the learner can find the downbeat.
  final bool accentFirstBeat;

  bool get audible => clickMode == PhraseClickMode.audibleCountIn;
}

/// One attack in the phrase, already converted to the scorer's fixed grid.
///
/// [bar] is a zero-based bar in the piece. Add one for the number the learner
/// sees. [beatInBar] is one-based and is kept as a double because pickups and
/// eighth notes do not fall on whole beats.
class PhrasePlayTarget {
  const PhrasePlayTarget({
    required this.index,
    required this.midi,
    required this.onsetSeconds,
    required this.durationSeconds,
    required this.bar,
    required this.startBeat,
    required this.durationBeats,
    required this.beatInBar,
    required this.writtenNote,
  });

  /// Stable target index used by [PhraseScorer] and note feedback.
  final int index;

  /// Sounding MIDI pitch. Guitar written pitch is an octave higher.
  final int midi;

  /// Expected onset from the start of the recording, including the count-in.
  final double onsetSeconds;

  final double durationSeconds;

  /// Zero-based bar in the piece, including [Phrase.startBar].
  final int bar;

  /// Beat offset from the start of the phrase, without the count-in.
  final double startBeat;

  final double durationBeats;

  /// One-based beat inside the bar.
  final double beatInBar;

  /// The note as written on the staff, used for feedback spelling.
  final Note writtenNote;

  /// The one-based bar number shown to the learner.
  int get displayBar => bar + 1;

  TargetNote toTargetNote() => TargetNote(
    index: index,
    midi: midi,
    onsetSeconds: onsetSeconds,
    durationSeconds: durationSeconds,
    bar: bar,
  );
}

/// A phrase prepared for playback and scoring.
///
/// The prompt owns the fixed click grid: every [PhrasePlayTarget.onsetSeconds]
/// is derived from the phrase's beat positions, the target BPM, and the
/// count-in. It never reads a wall clock.
///
/// Ties are folded into one target: a tied continuation has no new attack, so
/// scoring it as a separate note would always be indeterminate. Rests keep the
/// grid but do not become targets. [Phrase.pickupBeats] makes the first bar
/// shorter, so bar and beat labels stay correct for an anacrusis.
class PhrasePlayPrompt {
  PhrasePlayPrompt({
    required Phrase phrase,
    int? bpm,
    int intonationToleranceCents = 30,
    int countInBeats = 4,
    PhraseBackingSpec backing = const PhraseBackingSpec(),
  }) : this._(
         phrase: phrase,
         bpm: _resolveBpm(phrase, bpm),
         intonationToleranceCents: intonationToleranceCents,
         countInBeats: countInBeats,
         backing: backing,
       );

  PhrasePlayPrompt._({
    required this.phrase,
    required this.bpm,
    required this.intonationToleranceCents,
    required this.countInBeats,
    required this.backing,
  }) : targets = _buildTargets(phrase, bpm, countInBeats),
       timingToleranceMs = PhraseScorer.timingToleranceForBpm(bpm.toDouble()) {
    if (intonationToleranceCents < 0 || intonationToleranceCents > 100) {
      throw ArgumentError.value(
        intonationToleranceCents,
        'intonationToleranceCents',
        'must be between 0 and 100',
      );
    }
    if (countInBeats < 0) {
      throw ArgumentError.value(
        countInBeats,
        'countInBeats',
        'must not be negative',
      );
    }
    if (phrase.timeSignature.beatsPerBar <= 0) {
      throw ArgumentError.value(
        phrase.timeSignature,
        'phrase.timeSignature',
        'must have a positive bar length',
      );
    }
  }

  final Phrase phrase;

  /// Target tempo for this take.
  final int bpm;

  /// Exact-pitch tolerance for a note to count as in tune.
  final int intonationToleranceCents;

  /// Musical beats of silent/visible pre-roll before the phrase starts.
  final int countInBeats;

  final PhraseBackingSpec backing;

  /// Every attack in performance order, with ties folded.
  final List<PhrasePlayTarget> targets;

  /// Pedagogical onset tolerance for [bpm], in milliseconds.
  ///
  /// The scorer owns this rule. The prompt exposes it so the UI can explain
  /// the tolerance without hard-coding a second value.
  final double timingToleranceMs;

  double get beatSeconds => 60 / bpm;

  double get beatsPerBar => phrase.timeSignature.beatsPerBar;

  double get countInSeconds => countInBeats * beatSeconds;

  /// The performed length of the phrase, including any pickup.
  double get phraseSeconds {
    final beats = phrase.totalBeats > phrase.expectedTotalBeats
        ? phrase.totalBeats
        : phrase.expectedTotalBeats;
    return beats * beatSeconds;
  }

  /// How long a take should run: count-in, phrase, and the phrase's tail.
  double get recordingDurationSeconds => countInSeconds + phraseSeconds;

  /// Targets in the shape [PhraseScorer] expects.
  List<TargetNote> get targetNotes => [
    for (final target in targets) target.toTargetNote(),
  ];

  PhrasePlayTarget? targetForIndex(int index) {
    if (index < 0 || index >= targets.length) return null;
    return targets[index];
  }

  /// Synthetic preview of the phrase itself. The count-in is omitted so the
  /// learner hears the melody as soon as they tap play.
  SoundSpec get previewSpec => SoundSpec(
    bpm: bpm.toDouble(),
    label: phrase.title ?? phrase.id,
    events: [
      for (final target in targets)
        SoundEvent(
          midi: target.midi,
          startBeat: target.startBeat,
          durationBeats: target.durationBeats,
        ),
    ],
  );

  static int _resolveBpm(Phrase phrase, int? bpm) {
    final value = bpm ?? phrase.targetTempoBpm;
    if (value <= 0) {
      throw ArgumentError.value(value, 'bpm', 'must be positive');
    }
    return value;
  }

  static List<PhrasePlayTarget> _buildTargets(
    Phrase phrase,
    int bpm,
    int countInBeats,
  ) {
    if (phrase.events.isEmpty) return const <PhrasePlayTarget>[];

    final beatSeconds = 60 / bpm;
    final spans = _barSpans(phrase);
    final targets = <PhrasePlayTarget>[];
    var tiedFromPrevious = false;

    for (var index = 0; index < phrase.events.length; index++) {
      final event = phrase.events[index];
      if (event.isRest) {
        tiedFromPrevious = false;
        continue;
      }
      if (tiedFromPrevious) {
        tiedFromPrevious = event.tieToNext;
        continue;
      }

      final written = event.writtenNote;
      if (written == null) {
        tiedFromPrevious = event.tieToNext;
        continue;
      }

      // A tie chain has one attack and one sustained duration. Following the
      // chain here keeps the target list identical to what the learner plays.
      var endBeat = event.endBeat;
      var chainIndex = index;
      while (chainIndex + 1 < phrase.events.length &&
          phrase.events[chainIndex].tieToNext) {
        final next = phrase.events[chainIndex + 1];
        if (!next.isNote) break;
        chainIndex++;
        endBeat = next.endBeat;
      }

      final durationBeats = endBeat - event.startBeat;
      if (!durationBeats.isFinite || durationBeats <= 0) {
        tiedFromPrevious = event.tieToNext;
        continue;
      }

      final localBar = _localBarForBeat(spans, event.startBeat);
      final span = spans[localBar];
      targets.add(
        PhrasePlayTarget(
          index: targets.length,
          midi: Guitar.soundingMidiForWritten(written),
          onsetSeconds: (countInBeats + event.startBeat) * beatSeconds,
          durationSeconds: durationBeats * beatSeconds,
          bar: phrase.startBar - 1 + localBar,
          startBeat: event.startBeat,
          durationBeats: durationBeats,
          beatInBar: event.startBeat - span.start + 1,
          writtenNote: written,
        ),
      );
      tiedFromPrevious = event.tieToNext;
    }

    return List<PhrasePlayTarget>.unmodifiable(targets);
  }

  /// Bar spans in phrase-local beats. The first span is the pickup length when
  /// the phrase declares one; the rest use the time signature.
  static List<({double start, double end})> _barSpans(Phrase phrase) {
    final beatsPerBar = phrase.timeSignature.beatsPerBar;
    final spans = <({double start, double end})>[];
    var cursor = 0.0;
    final declaredBars = phrase.bars > 0 ? phrase.bars : 1;
    for (var bar = 0; bar < declaredBars; bar++) {
      final length = bar == 0 && phrase.pickupBeats > 0
          ? phrase.pickupBeats
          : beatsPerBar;
      spans.add((start: cursor, end: cursor + length));
      cursor += length;
    }

    // A malformed phrase may have events past its declared bars. Extend the
    // spans defensively so bar labels stay finite instead of throwing.
    var guard = 0;
    while (cursor < phrase.totalBeats - 1e-9 && guard < 256) {
      spans.add((start: cursor, end: cursor + beatsPerBar));
      cursor += beatsPerBar;
      guard++;
    }
    return spans;
  }

  static int _localBarForBeat(
    List<({double start, double end})> spans,
    double beat,
  ) {
    for (var index = 0; index < spans.length; index++) {
      if (beat < spans[index].end - 1e-9) return index;
    }
    return spans.length - 1;
  }
}
