import '../../content/pieces/phrase_objectives.dart';
import '../../core/audio/phrase_prompt.dart';
import '../../core/learning/note_objective.dart';
import '../../core/learning/objective.dart';
import '../../core/learning/phrase_objective.dart';
import '../../core/learning/progress.dart';
import '../../core/music/guitar.dart';
import '../../core/music/note.dart';
import '../../core/music/sound_spec.dart';

/// The display form of the one target a Today session is built around.
///
/// A target is either a registered phrase, a written note, or a theory-style
/// skill that has no playable preview. The screen uses this value object instead
/// of guessing from the objective id.
class TodayTargetView {
  const TodayTargetView({
    required this.title,
    required this.detail,
    this.note,
    this.phrase,
  });

  final String title;
  final String detail;

  /// The written note for a reading target. Null for phrase and theory targets.
  final Note? note;

  /// The registered phrase when the target is repertoire content.
  final PhraseContentRecord? phrase;

  bool get hasPhrase => phrase != null;
}

/// The stable phrase id a target points at, if any.
///
/// Reads the T2.11 phrase-objective payload first and falls back to the stored
/// objective id so a legacy `phrase:<phraseId>` skill still resolves.
String? todayPhraseIdFor(ObjectiveRef target) {
  final identified = target.data[PhraseObjectiveData.phraseId];
  if (identified is String && identified.isNotEmpty) return identified;
  return phraseIdFromObjectiveId(target.id);
}

/// Resolves [target] against the phrase registry and the note catalog.
TodayTargetView resolveTodayTarget(
  ObjectiveRef target,
  PhraseObjectiveRegistry registry,
) {
  final phraseId = todayPhraseIdFor(target);
  if (phraseId != null) {
    final record = registry.recordFor(phraseId);
    if (record != null) {
      final phrase = record.phrase;
      return TodayTargetView(
        title: phrase.title ?? phrase.id,
        detail:
            '${record.piece.title} · ${phrase.bars} '
            '${phrase.bars == 1 ? 'bar' : 'bars'} · ${phrase.targetTempoBpm} BPM',
        phrase: record,
      );
    }

    final title = target.data[PhraseObjectiveData.title];
    final pieceTitle = target.data[PhraseObjectiveData.pieceTitle];
    return TodayTargetView(
      title: title is String && title.isNotEmpty ? title : phraseId,
      detail: pieceTitle is String && pieceTitle.isNotEmpty
          ? pieceTitle
          : 'Phrase practice',
    );
  }

  final note = noteOf(target);
  if (note != null) {
    final position = Guitar.bestPosition(note);
    return TodayTargetView(
      title: note.display,
      detail: position == null
          ? 'Written note'
          : 'Written note · ${position.label}',
      note: note,
    );
  }

  final question = target.data['question'];
  return TodayTargetView(
    title: question is String && question.isNotEmpty ? question : target.id,
    detail: 'Reading Lab skill',
  );
}

/// A short, honest reason the target was chosen.
///
/// Every branch is derived from stored `ProgressState`; we never invent a
/// reason or a number.
String todayTargetReason(
  ProgressState progress,
  ObjectiveRef target,
  DateTime now,
) {
  final skill = progress.skills[target.id];
  if (skill == null) return 'It is the next skill in your course.';
  final dueAt = skill.dueAt;
  if (dueAt != null && !dueAt.isAfter(now)) {
    return 'It is due for review today.';
  }
  if (skill.fragile) {
    return 'It slipped before, so a calm revisit is worth it.';
  }
  if (skill.attempts >= 2 && skill.accuracy < 0.75) {
    return 'It is one of your weaker skills.';
  }
  return 'It is the skill you practiced most recently.';
}

/// A synthesized preview of the target.
///
/// Phrase targets use the same `SoundSpec` the phrase player plays. A note
/// target is a two-beat pluck on the guitar's sounding pitch. There is no human
/// reference recording in this build, so callers must label the result as a
/// synth preview, never as a reference performance.
SoundSpec? todaySynthPreview(
  ObjectiveRef target,
  PhraseObjectiveRegistry registry,
) {
  final view = resolveTodayTarget(target, registry);
  final record = view.phrase;
  if (record != null) {
    return PhrasePlayPrompt(phrase: record.phrase).previewSpec;
  }

  final note = view.note;
  if (note == null) return null;
  return SoundSpec(
    bpm: 60,
    label: 'Synth preview: ${note.display}',
    events: [
      SoundEvent(midi: Guitar.soundingMidiForWritten(note), durationBeats: 2),
    ],
  );
}

/// The one next step the learner leaves with.
String todayNextStep(ObjectiveRef target, TodayTargetView view) {
  if (view.hasPhrase) {
    return 'Next: play one bar of ${view.title} at half tempo tomorrow.';
  }
  if (view.note != null) {
    return 'Next: name and play ${view.note!.display} once before your next session.';
  }
  return 'Next: open ${view.title} in the Reading Lab tomorrow.';
}
