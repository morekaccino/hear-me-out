import 'dart:math';

import 'content_pack.dart';
import 'objective.dart';
import 'prompt.dart';
import 'session_shape.dart';
import 'template.dart';

/// Turns a shape and a ranked pool of objectives into a concrete session.
///
/// The composer is deliberately generic. It knows slots, roles, families, and
/// capabilities, never notes or chords. Everything topic-specific lives in a
/// template behind [ContentPack].
class SessionComposer {
  const SessionComposer(this.pack);

  final ContentPack pack;

  List<Prompt> compose({
    required SessionShape shape,
    required List<ObjectiveRef> newObjectives,
    required List<ObjectiveRef> reviewPool,
    required AnswerMode mode,
    required Set<Capability> capabilities,
    required Random random,
  }) {
    final entries = _buildEntries(shape, newObjectives, reviewPool);
    if (entries.length != shape.total) {
      throw StateError(
        'Session shape needs ${shape.total} slots, but only '
        '${entries.length} could be filled. Supply a longer review pool.',
      );
    }

    final ordered = _interleave(entries);
    final modes = _planModes(ordered, mode, capabilities);

    // Track which shapes an objective has already used this session, so four
    // exposures of one note are four different acts rather than four repeats.
    final used = <String, Set<String>>{};
    final prompts = <Prompt>[];
    for (var index = 0; index < ordered.length; index++) {
      final prompt = _render(
        ordered[index],
        modes[index],
        capabilities,
        random,
        used,
      );
      used.putIfAbsent(ordered[index].ref.id, () => <String>{}).add(
        prompt.templateId,
      );
      prompts.add(prompt);
    }
    assert(prompts.length == shape.total);
    return prompts;
  }

  /// Lays out one entry per slot before ordering.
  List<_Entry> _buildEntries(
    SessionShape shape,
    List<ObjectiveRef> newObjectives,
    List<ObjectiveRef> reviewPool,
  ) {
    final entries = <_Entry>[];
    var order = 0;

    // Derive both counts from the refs actually supplied. Trusting the shape's
    // own numbers would let a caller quietly produce a short session.
    final capacity = shape.total ~/ shape.exposures;
    final newCount = min(
      newObjectives.length,
      min(shape.newObjectives, capacity),
    );

    for (var index = 0; index < newCount; index++) {
      for (
        var occurrence = 0;
        occurrence < shape.exposures;
        occurrence++
      ) {
        entries.add(
          _Entry(
            ref: newObjectives[index],
            role: SessionShape.roleForOccurrence(occurrence),
            priority: 0,
            order: order++,
            occurrence: occurrence,
          ),
        );
      }
    }

    final reviewCount = shape.total - entries.length;
    for (var index = 0; index < reviewCount; index++) {
      if (reviewPool.isEmpty) break;
      entries.add(
        _Entry(
          ref: reviewPool[index % reviewPool.length],
          role: SlotRole.review,
          priority: 1,
          order: order++,
          occurrence: 0,
        ),
      );
    }

    return entries;
  }

  /// Orders entries so one objective never appears twice within two slots,
  /// while keeping the exposures of a single objective in teaching order.
  List<_Entry> _interleave(List<_Entry> entries) {
    final remaining = [...entries];
    final ordered = <_Entry>[];
    final recent = <String>[];

    while (remaining.isNotEmpty) {
      final counts = <String, int>{};
      for (final entry in remaining) {
        counts[entry.ref.id] = (counts[entry.ref.id] ?? 0) + 1;
      }

      final spaced = remaining
          .where((entry) => !recent.contains(entry.ref.id))
          .toList();
      final choices = spaced.isEmpty ? remaining : spaced;
      choices.sort((a, b) {
        final byCount = (counts[b.ref.id] ?? 0).compareTo(
          counts[a.ref.id] ?? 0,
        );
        if (byCount != 0) return byCount;
        final byPriority = a.priority.compareTo(b.priority);
        if (byPriority != 0) return byPriority;
        final byOrder = a.order.compareTo(b.order);
        if (byOrder != 0) return byOrder;
        return a.ref.id.compareTo(b.ref.id);
      });

      final chosen = choices.first;
      remaining.remove(chosen);
      ordered.add(chosen);
      recent.add(chosen.ref.id);
      if (recent.length > 2) recent.removeAt(0);
    }
    return ordered;
  }

  /// Chooses an answer surface for every slot.
  List<AnswerMode?> _planModes(
    List<_Entry> entries,
    AnswerMode requested,
    Set<Capability> capabilities,
  ) {
    final canPlay = capabilities.contains(Capability.microphone);
    final modes = List<AnswerMode?>.filled(entries.length, null);
    var playCount = 0;

    for (var index = 0; index < entries.length; index++) {
      final role = entries[index].role;
      if (role == SlotRole.teach) continue;
      if (canPlay && requested == AnswerMode.play) {
        modes[index] = AnswerMode.play;
        playCount++;
        continue;
      }
      if (role == SlotRole.guided) {
        modes[index] = AnswerMode.name;
        continue;
      }
      if (!canPlay || requested == AnswerMode.name) {
        modes[index] = AnswerMode.name;
        continue;
      }
      final usePlay = index.isEven || playCount < 3;
      modes[index] = usePlay ? AnswerMode.play : AnswerMode.name;
      if (usePlay) playCount++;
    }

    // Mixed mode promises some playing; make sure a short or unlucky session
    // still contains at least three chances to use the microphone.
    if (canPlay && requested == AnswerMode.mixed && playCount < 3) {
      for (var index = entries.length - 1; index >= 0 && playCount < 3; index--) {
        if (modes[index] != AnswerMode.name) continue;
        if (entries[index].role == SlotRole.guided) continue;
        modes[index] = AnswerMode.play;
        playCount++;
      }
    }
    return modes;
  }

  Prompt _render(
    _Entry entry,
    AnswerMode? mode,
    Set<Capability> capabilities,
    Random random,
    Map<String, Set<String>> used,
  ) {
    final wantsMicrophone = mode == AnswerMode.play;
    var candidates = pack.candidatesFor(
      family: entry.ref.family,
      role: entry.role,
      capabilities: capabilities,
      microphone: wantsMicrophone,
    );
    if (candidates.isEmpty) {
      candidates = pack.candidatesFor(
        family: entry.ref.family,
        role: entry.role,
        capabilities: capabilities,
        microphone: false,
      );
    }
    if (candidates.isEmpty) {
      throw StateError(
        'No template for ${entry.ref.family} ${entry.role} $mode. '
        'Register one in the content pack.',
      );
    }

    final previous = used[entry.ref.id] ?? const <String>{};
    final unused = [
      for (final candidate in candidates)
        if (!previous.contains(candidate.id)) candidate,
    ]..sort((a, b) => a.priority.compareTo(b.priority));
    final seen = [
      for (final candidate in candidates)
        if (previous.contains(candidate.id)) candidate,
    ]..sort((a, b) => a.priority.compareTo(b.priority));
    final orderedCandidates = [...unused, ...seen];

    for (final template in orderedCandidates) {
      final prompt = template.build(
        entry.ref,
        PromptContext(
          random: random,
          capabilities: capabilities,
          mode: mode ?? AnswerMode.name,
          role: entry.role,
          occurrence: entry.occurrence,
          isNew: entry.priority == 0,
        ),
      );
      if (prompt != null) return prompt;
    }

    throw StateError(
      'Every template for ${entry.ref.family} ${entry.role} declined '
      'objective ${entry.ref.id}.',
    );
  }
}

class _Entry {
  const _Entry({
    required this.ref,
    required this.role,
    required this.priority,
    required this.order,
    required this.occurrence,
  });

  final ObjectiveRef ref;
  final SlotRole role;
  final int priority;
  final int order;
  final int occurrence;
}
