import '../../core/music/note.dart';
import '../../core/music/note_event.dart';
import '../../core/music/phrase.dart';
import '../../core/music/piece.dart';
import '../../core/music/score.dart';
import '../score/authoring.dart';
import 'level_spec.dart';
import 'seeded_random.dart';

/// A generated etude candidate. It is never library content on its own.
///
/// The 60 reviewed etudes under `assets/content/etudes/` remain the shipped
/// core. A candidate is written to a scratch folder and stays `pending-human`
/// until a pedagogue approves it. See `lib/content/sight_reading/library.dart`.
class GeneratedEtude {
  const GeneratedEtude({
    required this.level,
    required this.seed,
    required this.spec,
    required this.key,
    required this.score,
  });

  final int level;
  final int seed;
  final EtudeLevelSpec spec;
  final EtudeKey key;
  final Score score;

  String get candidateId => score.piece.id;

  /// Serializes the candidate in the T3.2 authoring envelope.
  ///
  /// The `reviewedBy` string stays honest: a machine generated this file, no
  /// human has reviewed it, and it is not library content.
  Map<String, dynamic> toAuthoringJson() {
    return authoringToJson(
      score,
      meta: AuthoringMeta(
        author: 'Hear Me Out etude generator (beta)',
        source:
            'Generated candidate from the T3.7 beta generator; not reviewed '
            'library content.',
        reviewedBy: 'Pending human pedagogue review',
        notes:
            'Level $level candidate generated with seed $seed. '
            'Approval status: pending-human. The 60 reviewed etudes remain the '
            'shipped core; this file is not library content.',
        kind: 'etude',
        tier: spec.tier,
        stage: spec.stage,
      ),
    );
  }
}

/// Deterministic sight-reading etude generator.
///
/// The same `level` and `seed` always produce the same score and the same
/// authoring document. The generator writes nothing; the CLI in
/// `tool/content/generate_etude.dart` owns file output.
class EtudeGenerator {
  EtudeGenerator({required this.level, required this.seed})
    : spec = EtudeLevelSpec.forLevel(level) {
    if (seed < 0) {
      throw ArgumentError.value(
        seed,
        'seed',
        'Seed must be a non-negative integer.',
      );
    }
  }

  final int level;
  final int seed;
  final EtudeLevelSpec spec;

  static const Map<int, int> _openStringMidi = <int, int>{
    1: 64,
    2: 59,
    3: 55,
    4: 50,
    5: 45,
    6: 40,
  };

  /// Stepwise motif shapes. Every consecutive offset differs by at most one
  /// scale step, so level 1 stays inside its step-or-repeat interval rule.
  static const List<List<int>> _stepMotifs = <List<int>>[
    <int>[0, 1, 0, -1, 0],
    <int>[0, 1, 2, 1, 0],
    <int>[0, -1, -2, -1, 0],
    <int>[0, 1, 2, 3, 2, 1],
    <int>[0, 0, 1, 1, 0, -1],
    <int>[0, -1, 0, 1, 0],
  ];

  /// Motif shapes with small leaps for levels 2-5. The leap is clamped to the
  /// level interval limit after transposition.
  static const List<List<int>> _leapMotifs = <List<int>>[
    <int>[0, 1, 2, 3, 2, 1],
    <int>[0, 2, 1, 3, 2, 0],
    <int>[0, 1, 0, 2, 1, 0],
    <int>[0, 2, 4, 2, 1, 0],
    <int>[4, 3, 2, 1, 0],
    <int>[0, 1, 2, 1, 2, 3, 2, 1],
    <int>[0, -1, -2, -1, 0, 1, 0],
    <int>[0, 1, 0, -1, -2, -1, 0],
  ];

  /// Generates one candidate.
  GeneratedEtude generate() {
    final rng = SeededRandom(seed);
    final key = rng.pick(spec.allowedKeys);
    final meter = rng.pick(spec.allowedMeters);
    final rhythms = _buildRhythms(meter, rng);
    final phrases = <Phrase>[];
    final titles = _phraseTitles();
    final motif = _motifForLevel(rng);
    var startBar = 1;

    for (var index = 0; index < spec.phrasePlan.length; index++) {
      final plan = spec.phrasePlan[index];
      final phrase = _buildPhrase(
        phraseIndex: index,
        plan: plan,
        rhythm: rhythms[index],
        meter: meter,
        key: key,
        rng: rng,
        title: titles[index],
        startBar: startBar,
        isAnswer: plan.position == EtudePosition.second,
        motif: index == 2 && level == 3 ? motif : null,
      );
      phrases.add(phrase);
      startBar += plan.bars;
    }

    final piece = Piece(
      id: 'etude-candidate-l$level-s$seed',
      title: 'Sight-reading Etude L$level candidate (seed $seed)',
      composer: 'Hear Me Out',
      license: 'original',
      tuning: Tuning.standard,
      timeSignature: meter,
      key: key.name,
      sections: phrases.length > 1 ? const <String>['A', 'B'] : const ['A'],
    );

    return GeneratedEtude(
      level: level,
      seed: seed,
      spec: spec,
      key: key,
      score: Score(piece: piece, phrases: List<Phrase>.unmodifiable(phrases)),
    );
  }

  List<String> _phraseTitles() {
    return switch (level) {
      1 => const <String>['Four-bar statement'],
      2 => const <String>['Statement', 'Answer'],
      3 => const <String>['Statement', 'Answer', 'Return'],
      4 => const <String>[
        'First-position theme',
        'Shift to second position',
        'Return and cadence',
      ],
      _ => const <String>['First-position opening', 'Second-position answer'],
    };
  }

  Phrase _buildPhrase({
    required int phraseIndex,
    required EtudePhrasePlan plan,
    required List<_RhythmCell> rhythm,
    required TimeSignature meter,
    required EtudeKey key,
    required SeededRandom rng,
    required String title,
    required int startBar,
    required bool isAnswer,
    List<int>? motif,
  }) {
    final playable = _playablePitches(plan.position, key);
    if (playable.isEmpty) {
      throw StateError(
        'No playable ${key.name} pitch at level $level in '
        '${plan.position.name} position.',
      );
    }
    final home = _chooseHome(playable, key, rng);
    var scale = playable
        .where((pitch) => (pitch - home).abs() <= spec.registerRadiusSemitones)
        .toList();
    if (scale.length < 5) scale = playable;
    final homeIndex = scale.indexOf(home);

    final noteCount = rhythm.where((cell) => !cell.isRest).length;
    final indices = _buildMelodyIndices(
      scale: scale,
      homeIndex: homeIndex,
      noteCount: noteCount,
      rng: rng,
      isAnswer: isAnswer,
      motif: motif,
    );
    if (plan.position == EtudePosition.first) {
      _forceOpenString(indices, scale, plan.position);
    }
    _repairMelodicIntervals(indices, scale);
    _breakRepeatedRuns(indices, scale);
    var pitches = <int>[for (final index in indices) scale[index]];
    if (level == 3 && phraseIndex == 1) {
      pitches = _injectAccidental(
        pitches: pitches,
        scale: scale,
        indices: indices,
        key: key,
        position: plan.position,
      );
      pitches = _breakRepeatedPitchRuns(pitches, scale, key);
    }

    final events = _buildEvents(
      rhythm: rhythm,
      pitches: pitches,
      position: plan.position,
      ensureSecondPositionFrame: plan.position == EtudePosition.second,
    );
    final phraseId = 'etude-candidate-l$level-s$seed-p${phraseIndex + 1}';
    return Phrase(
      id: phraseId,
      title: title,
      bars: plan.bars,
      timeSignature: meter,
      events: List<NoteEvent>.unmodifiable(events),
      targetTempoBpm: spec.tempoBpm,
      skills: _skills(
        events: events,
        position: plan.position,
        key: key,
        phraseIndex: phraseIndex,
      ),
      difficulty: level,
      startBar: startBar,
      pickupBeats: 0,
    );
  }

  List<int> _buildMelodyIndices({
    required List<int> scale,
    required int homeIndex,
    required int noteCount,
    required SeededRandom rng,
    required bool isAnswer,
    List<int>? motif,
  }) {
    final motifA = motif ?? _motifForLevel(rng);
    final motifB = _motifForLevel(rng);
    final base = (homeIndex + (isAnswer ? 2 : 0)).clamp(0, scale.length - 1);
    final indices = <int>[];
    var previous = homeIndex;

    for (var index = 0; index < noteCount; index++) {
      final pattern = index < noteCount ~/ 2 ? motifA : motifB;
      final offset = pattern[index % pattern.length];
      var candidate = (base + offset).clamp(0, scale.length - 1);
      candidate = _moveWithinInterval(
        scale,
        candidate,
        previous,
        spec.maxIntervalSemitones,
      );
      if (indices.length >= 2 &&
          scale[candidate] == scale[indices[indices.length - 1]] &&
          scale[candidate] == scale[indices[indices.length - 2]]) {
        final nudge = candidate < scale.length - 1 ? 1 : -1;
        candidate = _moveWithinInterval(
          scale,
          (candidate + nudge).clamp(0, scale.length - 1),
          previous,
          spec.maxIntervalSemitones,
        );
      }
      indices.add(candidate);
      previous = candidate;
    }

    // Every phrase ends with a tonic. The penultimate note approaches it by a
    // scale step, which is one or two semitones.
    if (indices.length >= 2) {
      final finalIndex = homeIndex;
      indices[indices.length - 1] = finalIndex;
      final reference =
          indices[indices.length - 3 < 0
              ? indices.length - 2
              : indices.length - 3];
      final approaches = <int>[
        for (var index = 0; index < scale.length; index++)
          if (index != finalIndex &&
              (scale[index] - scale[finalIndex]).abs() <= 2)
            index,
      ];
      if (approaches.isEmpty) {
        for (var index = 0; index < scale.length; index++) {
          if (index != finalIndex) approaches.add(index);
        }
      }
      approaches.sort((a, b) {
        final byDistance = (scale[a] - scale[reference]).abs().compareTo(
          (scale[b] - scale[reference]).abs(),
        );
        return byDistance != 0 ? byDistance : a.compareTo(b);
      });
      indices[indices.length - 2] = approaches.first;
      if (indices.length >= 3) {
        indices[indices.length - 3] = _moveWithinInterval(
          scale,
          indices[indices.length - 3],
          indices[indices.length - 2],
          spec.maxIntervalSemitones,
        );
      }
    }
    return indices;
  }

  int _moveWithinInterval(
    List<int> scale,
    int index,
    int anchor,
    int maxInterval,
  ) {
    var result = index.clamp(0, scale.length - 1);
    while ((scale[result] - scale[anchor]).abs() > maxInterval) {
      if (result == anchor) break;
      result += result > anchor ? -1 : 1;
    }
    return result;
  }

  List<int> _motifForLevel(SeededRandom rng) {
    final motifs = level == 1 ? _stepMotifs : _leapMotifs;
    return motifs[rng.nextInt(motifs.length)];
  }

  void _forceOpenString(
    List<int> indices,
    List<int> scale,
    EtudePosition position,
  ) {
    if (position == EtudePosition.second || indices.isEmpty) return;
    final openPitches = <int>{
      for (final string in spec.allowedStrings)
        if (_openStringMidi[string] != null) _openStringMidi[string]!,
    };
    final openIndices = <int>[
      for (var index = 0; index < scale.length; index++)
        if (openPitches.contains(scale[index])) index,
    ];
    if (openIndices.isEmpty) return;

    // Place the open string on the first note, close to the generated pitch,
    // then repair the second note so the interval stays legal.
    var best = openIndices.first;
    for (final candidate in openIndices) {
      if ((scale[candidate] - scale[indices.first]).abs() <
          (scale[best] - scale[indices.first]).abs()) {
        best = candidate;
      }
    }
    indices[0] = best;
    if (indices.length >= 2) {
      indices[1] = _moveWithinInterval(
        scale,
        indices[1],
        best,
        spec.maxIntervalSemitones,
      );
    }
  }

  void _repairMelodicIntervals(List<int> indices, List<int> scale) {
    if (indices.length < 3) return;
    for (var pass = 0; pass < 6; pass++) {
      var changed = false;
      for (var index = 1; index < indices.length - 2; index++) {
        final repaired = _moveWithinInterval(
          scale,
          indices[index],
          indices[index - 1],
          spec.maxIntervalSemitones,
        );
        if (repaired != indices[index]) {
          indices[index] = repaired;
          changed = true;
        }
      }
      for (var index = indices.length - 3; index >= 1; index--) {
        final repaired = _moveWithinInterval(
          scale,
          indices[index],
          indices[index + 1],
          spec.maxIntervalSemitones,
        );
        if (repaired != indices[index]) {
          indices[index] = repaired;
          changed = true;
        }
      }
      if (!changed) return;
    }
  }

  void _breakRepeatedRuns(List<int> indices, List<int> scale) {
    if (indices.length < 3) return;
    for (var pass = 0; pass < 8; pass++) {
      var changed = false;
      var index = 0;
      while (index < indices.length) {
        var end = index;
        while (end + 1 < indices.length &&
            scale[indices[end + 1]] == scale[indices[index]]) {
          end++;
        }
        final runLength = end - index + 1;
        if (runLength <= spec.maxConsecutiveRepeatedNotes) {
          index = end + 1;
          continue;
        }

        int? target;
        for (var candidate = end; candidate >= index; candidate--) {
          if (candidate > 0 && candidate < indices.length - 2) {
            target = candidate;
            break;
          }
        }
        if (target == null) {
          index = end + 1;
          continue;
        }
        final targetIndex = target;

        final current = indices[targetIndex];
        final options = <int>[
          if (current > 0) current - 1,
          if (current < scale.length - 1) current + 1,
        ];
        options.sort((a, b) {
          final leftA = targetIndex > 0
              ? (scale[a] - scale[indices[targetIndex - 1]]).abs()
              : 0;
          final leftB = targetIndex > 0
              ? (scale[b] - scale[indices[targetIndex - 1]]).abs()
              : 0;
          return leftA.compareTo(leftB);
        });
        for (final option in options) {
          if (scale[option] == scale[current]) continue;
          if (targetIndex > 0 &&
              (scale[option] - scale[indices[targetIndex - 1]]).abs() >
                  spec.maxIntervalSemitones) {
            continue;
          }
          if (targetIndex + 1 < indices.length &&
              (scale[option] - scale[indices[targetIndex + 1]]).abs() >
                  spec.maxIntervalSemitones) {
            continue;
          }
          indices[targetIndex] = option;
          changed = true;
          break;
        }
        if (!changed) {
          for (final option in options) {
            if (scale[option] != scale[current]) {
              indices[targetIndex] = option;
              changed = true;
              break;
            }
          }
        }
        index = end + 1;
      }
      if (!changed) return;
    }
  }

  List<int> _breakRepeatedPitchRuns(
    List<int> pitches,
    List<int> scale,
    EtudeKey key,
  ) {
    if (pitches.length < 3) return pitches;
    final result = List<int>.from(pitches);
    for (var pass = 0; pass < 8; pass++) {
      var changed = false;
      var index = 0;
      while (index < result.length) {
        var end = index;
        while (end + 1 < result.length && result[end + 1] == result[index]) {
          end++;
        }
        final runLength = end - index + 1;
        if (runLength <= spec.maxConsecutiveRepeatedNotes) {
          index = end + 1;
          continue;
        }
        int? target;
        for (var candidate = end; candidate >= index; candidate--) {
          final pitchClass = result[candidate] % 12;
          if (candidate > 0 &&
              candidate < result.length - 2 &&
              key.containsPitchClass(pitchClass)) {
            target = candidate;
            break;
          }
        }
        if (target == null) {
          index = end + 1;
          continue;
        }
        final current = result[target];
        final options = <int>[
          for (final pitch in scale)
            if (pitch != current &&
                (pitch - current).abs() <= spec.maxIntervalSemitones)
              pitch,
        ]..sort((a, b) => (a - current).abs().compareTo((b - current).abs()));
        for (final option in options) {
          if (target > 0 &&
              (option - result[target - 1]).abs() > spec.maxIntervalSemitones) {
            continue;
          }
          if (target + 1 < result.length &&
              (option - result[target + 1]).abs() > spec.maxIntervalSemitones) {
            continue;
          }
          result[target] = option;
          changed = true;
          break;
        }
        if (!changed && options.isNotEmpty) {
          result[target] = options.first;
          changed = true;
        }
        index = end + 1;
      }
      if (!changed) return result;
    }
    return result;
  }

  List<int> _injectAccidental({
    required List<int> pitches,
    required List<int> scale,
    required List<int> indices,
    required EtudeKey key,
    required EtudePosition position,
  }) {
    if (pitches.length < 5) return pitches;

    if (key.isMinor) {
      // The natural seventh becomes the raised leading tone at the cadence.
      final seventh = key.degreePitchClass(6);
      final penultimate = pitches.length - 2;
      if (pitches[penultimate] % 12 != seventh) {
        final target = pitches[penultimate];
        final candidates =
            <int>[
              for (var index = 0; index < scale.length; index++)
                if (scale[index] % 12 == seventh) index,
            ]..sort(
              (a, b) => (scale[a] - target).abs().compareTo(
                (scale[b] - target).abs(),
              ),
            );
        if (candidates.isNotEmpty) {
          indices[penultimate] = candidates.first;
          pitches[penultimate] = scale[candidates.first];
          indices[penultimate - 1] = _moveWithinInterval(
            scale,
            indices[penultimate - 1],
            indices[penultimate],
            spec.maxIntervalSemitones,
          );
          pitches[penultimate - 1] = scale[indices[penultimate - 1]];
        }
      }
      final raised = pitches[penultimate] + 1;
      if (pitches[penultimate] % 12 == seventh &&
          _isPlayable(raised, position) &&
          (raised - pitches[penultimate - 1]).abs() <=
              spec.maxIntervalSemitones) {
        pitches[penultimate] = raised;
        return pitches;
      }
      return _addChromaticNeighbour(
        pitches: pitches,
        key: key,
        position: position,
      );
    }

    // Major: prefer a raised fourth degree that resolves into the dominant.
    final fourth = key.degreePitchClass(3);
    final dominant = key.degreePitchClass(4);
    for (var index = 1; index < pitches.length - 1; index++) {
      if (pitches[index] % 12 != fourth) continue;
      if (pitches[index + 1] % 12 != dominant) continue;
      final raised = pitches[index] + 1;
      if (!_isPlayable(raised, position)) continue;
      if ((raised - pitches[index - 1]).abs() > spec.maxIntervalSemitones) {
        continue;
      }
      pitches[index] = raised;
      return pitches;
    }

    final chromatic = _addChromaticNeighbour(
      pitches: pitches,
      key: key,
      position: position,
    );
    if (!identical(chromatic, pitches)) return chromatic;

    // Last resort: raise any fourth degree that stays inside the intervals.
    for (var index = 1; index < pitches.length - 1; index++) {
      if (pitches[index] % 12 != fourth) continue;
      final raised = pitches[index] + 1;
      if (!_isPlayable(raised, position)) continue;
      if ((raised - pitches[index - 1]).abs() > spec.maxIntervalSemitones) {
        continue;
      }
      if ((raised - pitches[index + 1]).abs() > spec.maxIntervalSemitones) {
        continue;
      }
      pitches[index] = raised;
      return pitches;
    }
    return pitches;
  }

  /// Adds one chromatic neighbour to a stepwise pair.
  ///
  /// The replacement stays inside the level interval limit, so the phrase
  /// keeps its shape. It is the fallback when a leading tone is not playable
  /// in the phrase's position window.
  List<int> _addChromaticNeighbour({
    required List<int> pitches,
    required EtudeKey key,
    required EtudePosition position,
  }) {
    for (var index = 1; index < pitches.length - 2; index++) {
      final current = pitches[index];
      final next = pitches[index + 1];
      if (current == next) continue;
      final candidate = current < next ? next - 1 : next + 1;
      if (candidate == current) continue;
      if (key.containsPitchClass(candidate % 12)) continue;
      if (!_isPlayable(candidate, position)) continue;
      if ((candidate - pitches[index - 1]).abs() > spec.maxIntervalSemitones) {
        continue;
      }
      final result = List<int>.from(pitches);
      result[index] = candidate;
      return result;
    }
    return pitches;
  }

  bool _isPlayable(int soundingMidi, EtudePosition position) =>
      _optionsFor(soundingMidi, position).isNotEmpty;

  List<NoteEvent> _buildEvents({
    required List<_RhythmCell> rhythm,
    required List<int> pitches,
    required EtudePosition position,
    required bool ensureSecondPositionFrame,
  }) {
    final events = <NoteEvent>[];
    var startBeat = 0.0;
    var pitchIndex = 0;
    int? previousString;
    for (final cell in rhythm) {
      if (cell.isRest) {
        events.add(
          NoteEvent(
            startBeat: startBeat,
            durationBeats: cell.duration,
            kind: NoteEventKind.rest,
          ),
        );
      } else {
        final pitch = pitches[pitchIndex++];
        final option = _chooseOption(pitch, position, previousString);
        previousString = option.string;
        events.add(
          NoteEvent(
            startBeat: startBeat,
            durationBeats: cell.duration,
            kind: NoteEventKind.note,
            writtenNote: Note.fromMidi(pitch + 12),
            soundingMidi: pitch,
            string: option.string,
            fret: option.fret,
          ),
        );
      }
      startBeat += cell.duration;
    }

    if (ensureSecondPositionFrame &&
        !events.any((event) => event.isNote && (event.fret ?? 0) >= 4)) {
      _forceSecondPositionFrame(events, position);
    }
    return events;
  }

  void _forceSecondPositionFrame(
    List<NoteEvent> events,
    EtudePosition position,
  ) {
    final noteIndexes = <int>[
      for (var index = 0; index < events.length; index++)
        if (events[index].isNote) index,
    ];
    for (var index = noteIndexes.length - 2; index >= 1; index--) {
      final eventIndex = noteIndexes[index];
      final event = events[eventIndex];
      final options = _optionsFor(
        event.soundingMidi!,
        position,
      ).where((option) => option.fret >= 4).toList();
      if (options.isEmpty) continue;
      options.sort((a, b) => a.fret.compareTo(b.fret));
      events[eventIndex] = event.copyWith(
        string: options.first.string,
        fret: options.first.fret,
      );
      return;
    }
  }

  ({int string, int fret}) _chooseOption(
    int soundingMidi,
    EtudePosition position,
    int? previousString,
  ) {
    final options = _optionsFor(soundingMidi, position);
    if (options.isEmpty) {
      throw StateError(
        'No ${position.name}-position fingering for MIDI $soundingMidi at '
        'level $level.',
      );
    }
    options.sort((a, b) {
      final scoreA = _optionScore(a, previousString);
      final scoreB = _optionScore(b, previousString);
      final byScore = scoreA.compareTo(scoreB);
      if (byScore != 0) return byScore;
      final byFret = a.fret.compareTo(b.fret);
      return byFret != 0 ? byFret : a.string.compareTo(b.string);
    });
    return options.first;
  }

  int _optionScore(({int string, int fret}) option, int? previousString) {
    final stringCost = previousString == null
        ? 0
        : (option.string - previousString).abs() * 10;
    final openBonus = option.fret == 0 ? -2 : 0;
    return stringCost + openBonus + option.fret;
  }

  List<({int string, int fret})> _optionsFor(
    int soundingMidi,
    EtudePosition position,
  ) {
    final low = position == EtudePosition.first
        ? spec.firstPositionLow
        : spec.secondPositionLow;
    final high = position == EtudePosition.first
        ? spec.firstPositionHigh
        : spec.secondPositionHigh;
    final options = <({int string, int fret})>[];
    for (final string in spec.allowedStrings) {
      final open = _openStringMidi[string];
      if (open == null) continue;
      final fret = soundingMidi - open;
      if (fret >= low && fret <= high) {
        options.add((string: string, fret: fret));
      }
    }
    return options;
  }

  List<int> _playablePitches(EtudePosition position, EtudeKey key) {
    final low = position == EtudePosition.first
        ? spec.firstPositionLow
        : spec.secondPositionLow;
    final high = position == EtudePosition.first
        ? spec.firstPositionHigh
        : spec.secondPositionHigh;
    final pitches = <int>{};
    for (final string in spec.allowedStrings) {
      final open = _openStringMidi[string];
      if (open == null) continue;
      for (var fret = low; fret <= high; fret++) {
        final soundingMidi = open + fret;
        if (key.containsPitchClass(soundingMidi % 12)) {
          pitches.add(soundingMidi);
        }
      }
    }
    final sorted = pitches.toList()..sort();
    return sorted;
  }

  int _chooseHome(List<int> playable, EtudeKey key, SeededRandom rng) {
    final tonics = playable
        .where((pitch) => pitch % 12 == key.tonicPitchClass)
        .toList();
    if (tonics.isEmpty) {
      throw StateError('No tonic ${key.name} in the playable register.');
    }
    final target = rng.pick(spec.registerTargets);
    tonics.sort((a, b) {
      final byDistance = (a - target).abs().compareTo((b - target).abs());
      return byDistance != 0 ? byDistance : a.compareTo(b);
    });
    return tonics.first;
  }

  List<List<_RhythmCell>> _buildRhythms(TimeSignature meter, SeededRandom rng) {
    final beatsPerBar = meter.beatsPerBar.round();
    final rhythms = <List<_RhythmCell>>[];
    for (var index = 0; index < spec.phrasePlan.length; index++) {
      if (level == 3 && index == 2 && rhythms.isNotEmpty) {
        rhythms.add(<_RhythmCell>[
          for (final cell in rhythms.first)
            _RhythmCell(cell.duration, isRest: cell.isRest),
        ]);
        continue;
      }
      final plan = spec.phrasePlan[index];
      final cells = <_RhythmCell>[];
      for (var bar = 0; bar < plan.bars; bar++) {
        final durations = index == 0 && bar == 0
            ? _seedBar(beatsPerBar)
            : _fillBar(beatsPerBar, rng);
        cells.addAll(durations.map((duration) => _RhythmCell(duration)));
      }
      if (index == 0 && spec.requiresRest) {
        _markRest(cells, rng);
      }
      rhythms.add(cells);
    }
    return rhythms;
  }

  List<double> _seedBar(int beatsPerBar) {
    if (level == 1) {
      return beatsPerBar == 4
          ? const <double>[2.0, 1.0, 1.0]
          : const <double>[2.0, 1.0];
    }
    if (level == 3) {
      return beatsPerBar == 4
          ? const <double>[1.5, 0.5, 1.0, 1.0]
          : const <double>[1.5, 0.5, 1.0];
    }
    return beatsPerBar == 4
        ? const <double>[1.0, 0.5, 0.5, 1.0, 1.0]
        : const <double>[1.0, 0.5, 0.5, 1.0];
  }

  List<double> _fillBar(int beatsPerBar, SeededRandom rng) {
    final smallest = spec.rhythmCells.reduce((a, b) => a < b ? a : b);
    final durations = <double>[];
    var remaining = beatsPerBar.toDouble();
    while (remaining > 1e-9) {
      final fitting = spec.rhythmCells
          .where((cell) => cell <= remaining + 1e-9)
          .toList();
      final safe = fitting
          .where(
            (cell) =>
                remaining - cell < 1e-9 || remaining - cell >= smallest - 1e-9,
          )
          .toList();
      final pool = safe.isEmpty ? fitting : safe;
      final cell = pool[rng.nextInt(pool.length)];
      durations.add(cell);
      remaining -= cell;
    }
    return durations;
  }

  void _markRest(List<_RhythmCell> cells, SeededRandom rng) {
    final candidates = <int>[
      for (var index = 1; index < cells.length - 2; index++) index,
    ];
    if (candidates.isEmpty) return;
    final index = candidates[rng.nextInt(candidates.length)];
    cells[index] = _RhythmCell(cells[index].duration, isRest: true);
  }

  List<String> _skills({
    required List<NoteEvent> events,
    required EtudePosition position,
    required EtudeKey key,
    required int phraseIndex,
  }) {
    final skills = <String>[];
    if (position == EtudePosition.first) {
      skills.add('note-reading.first-position');
    } else {
      skills.add('note-reading.second-position');
      skills.add('technique.position-shift');
    }
    final frets = <int>[
      for (final event in events)
        if (event.isNote && event.fret != null) event.fret!,
    ];
    if (frets.contains(0)) skills.add('note-reading.open-strings');

    final durations = <double>{for (final event in events) event.durationBeats};
    if (durations.any((duration) => (duration - 0.5).abs() < 1e-9)) {
      skills.add('rhythm.eighth-notes');
    }
    if (durations.any((duration) => (duration - 1.0).abs() < 1e-9)) {
      skills.add('rhythm.quarter-notes');
    }
    if (durations.any((duration) => (duration - 2.0).abs() < 1e-9)) {
      skills.add('rhythm.half-notes');
    }
    if (durations.any(
      (duration) =>
          (duration - 1.5).abs() < 1e-9 || (duration - 3.0).abs() < 1e-9,
    )) {
      skills.add('rhythm.dotted-rhythms');
    }
    if (events.any((event) => event.isRest)) {
      skills.add('rhythm.rests');
    }

    final accidentals = <int>{
      for (final event in events)
        if (event.isNote && event.writtenNote != null)
          event.writtenNote!.midi % 12,
    }.where((pitchClass) => !key.containsPitchClass(pitchClass));
    if (accidentals.isNotEmpty) skills.add('technique.accidentals');

    skills.add('sightreading.phrase-endings');
    if (level == 3 && (phraseIndex == 0 || phraseIndex == 2)) {
      skills.add('sightreading.rhythmic-motif');
    }
    return List<String>.unmodifiable(skills);
  }
}

/// One rhythm slot before pitches are attached.
class _RhythmCell {
  const _RhythmCell(this.duration, {this.isRest = false});

  final double duration;
  final bool isRest;
}
