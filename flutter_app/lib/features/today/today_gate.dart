import '../phrase/phrase_loop_flag.dart';

/// Whether the Today surface may replace the Learn/Path home.
///
/// This is the same decision 0001 switch as [phraseLoopEnabled]; the
/// indirection keeps the phrase module out of `HomeShell`'s imports while
/// preserving the compile-time gate. There is no production path that sets it.
const bool todayEnabled = phraseLoopEnabled;
