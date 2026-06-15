import 'dart:math';
import '../../config/constants.dart';

int frequencyToMidi(double frequency) {
  if (frequency <= 0) return 0;
  return (69 + 12 * (log(frequency / 440.0) / log(2))).round();
}

String midiToNoteName(int midi) {
  final noteIndex = midi % 12;
  final octave = (midi / 12).floor() - 1;
  final noteName = AppConstants.noteNames[noteIndex];
  return '$noteName$octave';
}

String frequencyToNoteName(double frequency) {
  final midi = frequencyToMidi(frequency);
  return midiToNoteName(midi);
}

String shiftNoteOctave(String noteName, int shift) {
  final notePart = noteName.replaceAll(RegExp(r'\d'), '');
  final octavePart = int.tryParse(noteName.replaceAll(RegExp(r'[^0-9]'), '')) ?? 4;
  final newOctave = octavePart + shift;
  if (newOctave < 0 || newOctave > 8) return noteName;
  return '$notePart$newOctave';
}
