import '../music/guitar.dart';
import '../music/note.dart';
import 'pitch_source.dart';

class PitchReading {
  const PitchReading({
    required this.frequency,
    required this.midi,
    required this.cents,
    required this.clarity,
    required this.note,
    required this.voiced,
  });

  final double frequency;
  final double midi;
  final double cents;
  final double clarity;
  final Note? note;
  final bool voiced;

  static const silent = PitchReading(
    frequency: 0,
    midi: 0,
    cents: 0,
    clarity: 0,
    note: null,
    voiced: false,
  );
}

enum MatchState { silent, listening, correct, wrong, octave }

class MatchResult {
  const MatchResult({required this.state, required this.reading, this.target});

  final MatchState state;
  final PitchReading reading;
  final Note? target;

  bool get isFinal =>
      state == MatchState.correct ||
      state == MatchState.wrong ||
      state == MatchState.octave;
}

class NoteMatcher {
  NoteMatcher({this.a4 = 440, this.toleranceCents = 30});

  final double a4;
  final int toleranceCents;

  Note? _target;
  int _targetSoundingMidi = 0;
  DateTime? _graceUntil;
  int _lastMidi = -1;
  int _stableFrames = 0;
  bool _locked = false;
  MatchState _lockedState = MatchState.listening;

  Note? get target => _target;

  void startExercise(
    Note target, {
    DateTime? now,
    Duration grace = const Duration(milliseconds: 250),
  }) {
    _target = target;
    _targetSoundingMidi = Guitar.soundingMidiForWritten(target);
    _graceUntil = (now ?? DateTime.now()).add(grace);
    _lastMidi = -1;
    _stableFrames = 0;
    _locked = false;
    _lockedState = MatchState.listening;
  }

  void clear() {
    _target = null;
    _lastMidi = -1;
    _stableFrames = 0;
    _locked = false;
  }

  MatchResult addFrame(PitchFrame frame, {DateTime? now}) {
    final target = _target;
    final reading = _readingFor(frame);

    if (target == null) {
      return MatchResult(state: MatchState.listening, reading: reading);
    }
    if (_locked) {
      return MatchResult(state: _lockedState, reading: reading, target: target);
    }
    if (!reading.voiced) {
      _lastMidi = -1;
      _stableFrames = 0;
      return MatchResult(
        state: MatchState.silent,
        reading: reading,
        target: target,
      );
    }

    final current = now ?? DateTime.now();
    if (_graceUntil != null && current.isBefore(_graceUntil!)) {
      return MatchResult(
        state: MatchState.listening,
        reading: reading,
        target: target,
      );
    }

    final roundedMidi = reading.midi.round();
    if (roundedMidi == _lastMidi) {
      _stableFrames++;
    } else {
      _lastMidi = roundedMidi;
      _stableFrames = 1;
    }

    if (_stableFrames < 3) {
      return MatchResult(
        state: MatchState.listening,
        reading: reading,
        target: target,
      );
    }

    if (roundedMidi == _targetSoundingMidi) {
      if (reading.cents.abs() <= toleranceCents) {
        _locked = true;
        _lockedState = MatchState.correct;
        return MatchResult(
          state: MatchState.correct,
          reading: reading,
          target: target,
        );
      }
      return MatchResult(
        state: MatchState.listening,
        reading: reading,
        target: target,
      );
    }

    if ((roundedMidi - _targetSoundingMidi).abs() == 12 && _stableFrames >= 6) {
      _locked = true;
      _lockedState = MatchState.octave;
      return MatchResult(
        state: MatchState.octave,
        reading: reading,
        target: target,
      );
    }

    if (_stableFrames >= 6) {
      _locked = true;
      _lockedState = MatchState.wrong;
      return MatchResult(
        state: MatchState.wrong,
        reading: reading,
        target: target,
      );
    }

    return MatchResult(
      state: MatchState.listening,
      reading: reading,
      target: target,
    );
  }

  PitchReading _readingFor(PitchFrame frame) {
    if (!frame.voiced || frame.frequency <= 0) {
      return PitchReading(
        frequency: frame.frequency,
        midi: 0,
        cents: 0,
        clarity: frame.clarity,
        note: null,
        voiced: false,
      );
    }
    final midi = frequencyToMidi(frame.frequency, a4: a4);
    final rounded = midi.round();
    return PitchReading(
      frequency: frame.frequency,
      midi: midi,
      cents: centsFromMidi(midi),
      clarity: frame.clarity,
      note: Note.fromMidi(rounded),
      voiced: true,
    );
  }
}
