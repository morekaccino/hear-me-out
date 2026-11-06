/// The three possible verdicts for one attempt.
///
/// This is the single domain-level declaration. Audio scoring and UI code
/// import it from here; [phrase_scorer.dart](../audio/phrase_scorer.dart)
/// re-exports it for callers that already import the scorer.
enum AttemptOutcome {
  correct,
  incorrect,

  /// The app could not tell what happened. This means "retry", not "fail":
  /// it must not reach the scheduler or change any counter.
  indeterminate;

  bool get isDeterminate => this != AttemptOutcome.indeterminate;
}
