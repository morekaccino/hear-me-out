import '../../core/learning/objective.dart';
import '../../core/music/note.dart';

/// One written note, on the staff and on the fretboard.
///
/// The id is stable so progress can be stored against it later: `note:E4`.
String noteObjectiveId(Note note) => 'note:${note.id}';

ObjectiveRef noteObjective(Note note, {int stage = 0}) => ObjectiveRef(
  noteObjectiveId(note),
  family: SkillFamily.noteReading,
  stage: stage,
  data: {'note': note},
);

Note? noteOf(ObjectiveRef ref) => ref.data['note'] as Note?;
