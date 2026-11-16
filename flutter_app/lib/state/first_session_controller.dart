import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Remembers that the learner chose SKIP FOR NOW in this app run.
///
/// The skipped status is persisted in `ProgressState`; this flag is the
/// session-scoped half of T5.8's rule. It hides the Path card until the process
/// restarts and is deliberately never saved, so the invitation returns on the
/// next app open instead of disappearing forever.
class FirstSessionRunSkip extends Notifier<bool> {
  @override
  bool build() => false;

  void markSkipped() => state = true;
}

final firstSessionRunSkipProvider =
    NotifierProvider<FirstSessionRunSkip, bool>(FirstSessionRunSkip.new);
