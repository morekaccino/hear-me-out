import '../music/note.dart';
import 'objective.dart';

/// Prefix for a note objective id. Keeping it in one place prevents content
/// callers from re-implementing the storage format.
const String noteObjectivePrefix = 'note:';

/// One written note, on the staff and on the fretboard.
///
/// The id is stable so progress can be stored against it: `note:E4`.
String noteObjectiveId(Note note) => '$noteObjectivePrefix${note.id}';

/// Parses a note objective id, or returns null when [id] is another family.
Note? noteFromObjectiveId(String id) {
  if (!id.startsWith(noteObjectivePrefix)) return null;
  return Note.tryParse(id.substring(noteObjectivePrefix.length));
}

ObjectiveRef noteObjective(Note note, {int stage = 0}) => ObjectiveRef(
  noteObjectiveId(note),
  family: SkillFamily.noteReading,
  stage: stage,
  data: {'note': note},
);

Note? noteOf(ObjectiveRef ref) => ref.data['note'] as Note?;
