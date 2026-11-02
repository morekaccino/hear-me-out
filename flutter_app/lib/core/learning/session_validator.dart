import 'prompt.dart';
import 'session_shape.dart';

/// Pacing rules a generated session must satisfy.
///
/// This is the guardrail against a future template quietly turning every
/// lesson into ten questions of the same kind.
class SessionValidator {
  const SessionValidator({this.spacing = 1, this.maxTypeRun});

  /// How many slots must separate two prompts for the same objective.
  ///
  /// Defaults to one: never twice in a row. Stricter spacing is best effort in
  /// the composer when counts are uneven, so it is not asserted by default.
  final int spacing;

  /// Maximum run of one template in a row. Null disables the rule, which is
  /// what all-name checkpoints need.
  final int? maxTypeRun;

  List<String> violations(
    List<Prompt> prompts, {
    required SessionShape shape,
  }) {
    final problems = <String>[];

    if (prompts.length != shape.total) {
      problems.add('expected ${shape.total} prompts, found ${prompts.length}');
    }

    final teachPrompts = prompts.where((prompt) => prompt.isTeach).toList();
    if (teachPrompts.length > shape.newObjectives) {
      problems.add(
        '${teachPrompts.length} teach cards for '
        '${shape.newObjectives} new objectives',
      );
    }
    final taught = <String>{};
    for (final prompt in teachPrompts) {
      if (prompt.isScored) {
        problems.add('teach card ${prompt.objective.id} is scored');
      }
      if (!taught.add(prompt.objective.id)) {
        problems.add('objective ${prompt.objective.id} is taught twice');
      }
    }

    for (var index = 1; index < prompts.length; index++) {
      if (prompts[index].objective == prompts[index - 1].objective) {
        problems.add(
          'objective ${prompts[index].objective.id} repeats at $index',
        );
      }
    }

    // Spacing only means something when there are enough distinct objectives
    // to interleave. Two ideas can only alternate, and the adjacency check
    // above already covers that case.
    final distinct = prompts.map((prompt) => prompt.objective.id).toSet().length;
    final effective = spacing < distinct - 1 ? spacing : distinct - 1;
    if (effective > 1) {
      for (var index = effective; index < prompts.length; index++) {
        if (prompts[index].objective ==
            prompts[index - effective].objective) {
          problems.add(
            'objective ${prompts[index].objective.id} is too close at $index',
          );
        }
      }
    }

    final limit = maxTypeRun;
    if (limit != null) {
      var run = 1;
      for (var index = 1; index < prompts.length; index++) {
        run = prompts[index].templateId == prompts[index - 1].templateId
            ? run + 1
            : 1;
        if (run > limit) {
          problems.add(
            'template ${prompts[index].templateId} repeats at $index',
          );
        }
      }
    }

    return problems;
  }
}
