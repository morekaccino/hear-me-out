/// Decision 0001 gate for the phrase loop.
///
/// The phrase player, phrase progress, and any mic-first phrase UI stay
/// unreachable from main navigation while this is false. There is deliberately
/// no production path that flips it: the switch is a compile-time constant so a
/// build either opts in for evaluation or ships without the loop.
///
/// The gate opens only after T1.7 passes with real corpus evidence. Until then
/// no screen, ticket, or document may claim that microphone phrase scoring is
/// validated. Unit and widget tests may construct the phrase player directly.
const bool phraseLoopEnabled = false;
