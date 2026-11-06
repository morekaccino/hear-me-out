/// A small deterministic pseudo-random generator for content tooling.
///
/// `dart:math` `Random(seed)` is not a stable contract across SDK versions.
/// The etude generator must return the same candidate for the same level and
/// seed forever, so it uses this local Mulberry32 implementation instead.
/// The arithmetic is masked to 32 bits, so it behaves the same on the Dart VM
/// and on the web.
class SeededRandom {
  SeededRandom(int seed) : _state = seed & 0xFFFFFFFF;

  int _state;

  /// Next unsigned 32-bit value.
  int nextUint32() {
    _state = (_state + 0x6D2B79F5) & 0xFFFFFFFF;
    var t = _state;
    t = ((t ^ (t >>> 15)) * (t | 1)) & 0xFFFFFFFF;
    t = (t ^ (t + (((t ^ (t >>> 7)) * (t | 61)) & 0xFFFFFFFF))) & 0xFFFFFFFF;
    return (t ^ (t >>> 14)) & 0xFFFFFFFF;
  }

  /// Uniform double in `[0, 1)`.
  double nextDouble() => nextUint32() / 4294967296.0;

  /// Uniform integer in `[0, max)`.
  int nextInt(int max) {
    if (max <= 0) {
      throw ArgumentError.value(max, 'max', 'must be greater than zero');
    }
    return nextUint32() % max;
  }

  /// Picks one element from a non-empty list.
  T pick<T>(List<T> values) {
    if (values.isEmpty) {
      throw ArgumentError.value(values, 'values', 'must not be empty');
    }
    return values[nextInt(values.length)];
  }
}
