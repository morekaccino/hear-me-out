import '../media/recording_index.dart';
import 'phrase_objective.dart';
import 'progress.dart';
import 'skill.dart';

/// The four honest states on the mastery map.
enum MasteryKind { canPlay, shaky, reading, next }

/// One row on the mastery map.
class MasteryEntry {
  const MasteryEntry({
    required this.kind,
    required this.title,
    this.subtitle = '',
    this.tempoBpm,
    this.date,
    this.recordingTakeId,
    this.phraseId,
    this.pieceId,
  });

  final MasteryKind kind;

  /// Human-readable phrase or objective title.
  final String title;

  /// The piece title for a phrase, or a short reason for an atomic skill.
  final String subtitle;

  /// Target tempo for a phrase entry, when the content knows it.
  final int? tempoBpm;

  /// The latest mastery date for a can-play phrase.
  final DateTime? date;

  /// The latest saved take for this phrase, when one exists.
  final String? recordingTakeId;

  final String? phraseId;
  final String? pieceId;
}

/// A progress view built from real progress and recordings.
///
/// There is no lesson-completion percentage here. "Can play" exists only when
/// [PhraseProgress.isPerformanceMastered] proves performance mastery against
/// the current content version.
class MasteryMap {
  const MasteryMap({
    required this.canPlay,
    required this.shaky,
    required this.reading,
    required this.next,
    required this.readingMasteredCount,
    required this.readingTrackedCount,
  });

  final List<MasteryEntry> canPlay;
  final List<MasteryEntry> shaky;
  final List<MasteryEntry> reading;
  final List<MasteryEntry> next;

  /// Mastered note and rhythm skills.
  final int readingMasteredCount;

  /// Note and rhythm skills with any stored progress.
  final int readingTrackedCount;

  static MasteryMap build({
    required ProgressState progress,
    required PhraseContentCatalog registry,
    required Iterable<RecordingTake> takes,
    required DateTime now,
  }) {
    final records = <String, PhraseContentSummary>{
      for (final record in registry.allRecords) record.phraseId: record,
    };
    final latestTake = <String, RecordingTake>{};
    for (final take in takes) {
      final phraseId = take.phraseId;
      if (phraseId == null) continue;
      final previous = latestTake[phraseId];
      if (previous == null || take.createdAt.isAfter(previous.createdAt)) {
        latestTake[phraseId] = take;
      }
    }

    final canPlay = <MasteryEntry>[];
    for (final entry in progress.phraseProgress.entries) {
      final record = records[entry.key];
      if (record == null) continue;
      final phrase = entry.value;
      if (!phrase.isPerformanceMastered(record.contentVersion)) continue;
      canPlay.add(
        MasteryEntry(
          kind: MasteryKind.canPlay,
          title: record.phraseTitle,
          subtitle: record.pieceTitle,
          tempoBpm: record.targetTempoBpm,
          date: phrase.lastMasteryAt ?? _lastDayDate(phrase.masteryDays),
          recordingTakeId: latestTake[entry.key]?.id,
          phraseId: record.phraseId,
          pieceId: record.pieceId,
        ),
      );
    }
    canPlay.sort((a, b) {
      final byDate = (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0));
      return byDate != 0 ? byDate : a.title.compareTo(b.title);
    });

    final shakySkills =
        progress.skills.values
            .where(
              (skill) =>
                  _isAtomic(skill) && (skill.fragile || _isDue(skill, now)),
            )
            .toList()
          ..sort((a, b) {
            final aDue = a.dueAt ?? DateTime(9999);
            final bDue = b.dueAt ?? DateTime(9999);
            final byDue = aDue.compareTo(bDue);
            if (byDue != 0) return byDue;
            if (a.fragile != b.fragile) return a.fragile ? -1 : 1;
            return a.objectiveId.compareTo(b.objectiveId);
          });
    final shaky = [
      for (final skill in shakySkills.take(5))
        MasteryEntry(
          kind: MasteryKind.shaky,
          title: readableObjectiveId(skill.objectiveId),
          subtitle: _shakyReason(skill, now),
        ),
    ];

    final readingSkills = progress.skills.values
        .where(
          (skill) =>
              skill.family == SkillFamily.noteReading ||
              skill.family == SkillFamily.rhythm,
        )
        .toList();
    final masteredReading =
        readingSkills.where((skill) => skill.mastered).toList()
          ..sort((a, b) => a.objectiveId.compareTo(b.objectiveId));

    final dueAtomic =
        progress.skills.values
            .where((skill) => _isAtomic(skill) && _isDue(skill, now))
            .toList()
          ..sort((a, b) {
            final aDue = a.dueAt ?? DateTime(9999);
            final bDue = b.dueAt ?? DateTime(9999);
            final byDue = aDue.compareTo(bDue);
            return byDue != 0 ? byDue : a.objectiveId.compareTo(b.objectiveId);
          });

    final next = <MasteryEntry>[
      for (final skill in dueAtomic)
        MasteryEntry(
          kind: MasteryKind.next,
          title: readableObjectiveId(skill.objectiveId),
          subtitle: 'Due for review',
        ),
    ];
    final nextPhrase = _firstUnmasteredPhrase(progress, registry);
    if (nextPhrase != null) {
      next.add(
        MasteryEntry(
          kind: MasteryKind.next,
          title: nextPhrase.phraseTitle,
          subtitle: '${nextPhrase.pieceTitle} · next phrase',
          tempoBpm: nextPhrase.targetTempoBpm,
          phraseId: nextPhrase.phraseId,
          pieceId: nextPhrase.pieceId,
        ),
      );
    }

    return MasteryMap(
      canPlay: List<MasteryEntry>.unmodifiable(canPlay),
      shaky: List<MasteryEntry>.unmodifiable(shaky),
      reading: List<MasteryEntry>.unmodifiable([
        for (final skill in masteredReading.take(5))
          MasteryEntry(
            kind: MasteryKind.reading,
            title: readableObjectiveId(skill.objectiveId),
            subtitle: 'Reading skill at mastery',
          ),
      ]),
      next: List<MasteryEntry>.unmodifiable(next),
      readingMasteredCount: masteredReading.length,
      readingTrackedCount: readingSkills.length,
    );
  }
}

PhraseContentSummary? _firstUnmasteredPhrase(
  ProgressState progress,
  PhraseContentCatalog registry,
) {
  final records = registry.allRecords.toList()
    ..sort((a, b) {
      final byStage = a.stage.compareTo(b.stage);
      if (byStage != 0) return byStage;
      final byPiece = a.pieceId.compareTo(b.pieceId);
      return byPiece != 0 ? byPiece : a.phraseId.compareTo(b.phraseId);
    });
  for (final record in records) {
    final phrase = progress.phraseProgressFor(record.phraseId);
    if (phrase != null && phrase.isPerformanceMastered(record.contentVersion)) {
      continue;
    }
    return record;
  }
  return null;
}

bool _isAtomic(SkillProgress skill) {
  if (skill.family == SkillFamily.noteReading ||
      skill.family == SkillFamily.rhythm) {
    return true;
  }
  return skill.objectiveId.startsWith('interval:') ||
      skill.objectiveId.startsWith('ear:interval:');
}

bool _isDue(SkillProgress skill, DateTime now) =>
    skill.dueAt != null && !skill.dueAt!.isAfter(now);

String _shakyReason(SkillProgress skill, DateTime now) {
  if (skill.fragile && _isDue(skill, now)) return 'Fragile and due now';
  if (skill.fragile) return 'Fragile';
  if (_isDue(skill, now)) return 'Due now';
  return 'Shaky';
}

DateTime? _lastDayDate(Set<String> days) {
  if (days.isEmpty) return null;
  final sorted = days.toList()..sort();
  final parts = sorted.last.split('-');
  if (parts.length != 3) return null;
  return DateTime(
    int.tryParse(parts[0]) ?? 0,
    int.tryParse(parts[1]) ?? 1,
    int.tryParse(parts[2]) ?? 1,
  );
}

/// Turns a stable objective id into calm display text.
///
/// Examples: `note:E4` becomes `E4`; `rhythm:eighths` becomes
/// `Rhythm · eighths`; `ear:interval:m3:melodic` becomes
/// `Interval · m3 · melodic`.
String readableObjectiveId(String id) {
  if (id.startsWith('note:')) return id.substring('note:'.length);
  var value = id.startsWith('ear:') ? id.substring('ear:'.length) : id;
  final parts = value.split(':');
  if (parts.isEmpty) return id;
  final head = parts.first;
  final rest = parts
      .skip(1)
      .where((part) => part.isNotEmpty)
      .map((part) => part.replaceAll('_', ' '))
      .join(' · ');
  final base = head.isEmpty
      ? id
      : '${head.substring(0, 1).toUpperCase()}${head.substring(1)}';
  return rest.isEmpty ? base : '$base · $rest';
}
