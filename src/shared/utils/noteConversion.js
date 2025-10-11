import { NOTE_NAMES } from './constants'

export function frequencyToMidi(frequency) {
  return 69 + 12 * Math.log2(frequency / 440)
}

export function midiToNoteName(midi) {
  const noteIndex = Math.round(midi) % 12
  const octave = Math.floor(Math.round(midi) / 12) - 1
  return NOTE_NAMES[noteIndex] + octave
}

export function frequencyToNoteName(frequency) {
  return midiToNoteName(frequencyToMidi(frequency))
}

export function centsDifference(freq1, freq2) {
  return 1200 * Math.log2(freq2 / freq1)
}

export function notesMatch(detectedFreq, targetFreq, toleranceCents = 50) {
  const diff = Math.abs(centsDifference(detectedFreq, targetFreq))
  return diff <= toleranceCents
}

export function noteNameToFrequency(noteName) {
  const match = noteName.match(/^([A-G]#?)(\d+)$/)
  if (!match) return null
  
  const [, note, octave] = match
  const noteIndex = NOTE_NAMES.indexOf(note)
  if (noteIndex === -1) return null
  
  const midi = noteIndex + (parseInt(octave) + 1) * 12
  return 440 * Math.pow(2, (midi - 69) / 12)
}

export function shiftNoteOctave(noteName, octaveShift = 0) {
  const match = noteName.match(/^([A-G]#?)(-?\d+)$/)
  if (!match) return noteName
  const [, base, octaveStr] = match
  const octave = parseInt(octaveStr, 10) + octaveShift
  return `${base}${octave}`
}

export function soundingToWritten(noteName) {
  return shiftNoteOctave(noteName, 1)
}

export function writtenToSounding(noteName) {
  return shiftNoteOctave(noteName, -1)
}

export const NOTE_SYMBOLS = {
  'C': '\uE0A2',
  'C#': '\uE0A2',
  'D': '\uE0A2',
  'D#': '\uE0A2',
  'E': '\uE0A2',
  'F': '\uE0A2',
  'F#': '\uE0A2',
  'G': '\uE0A2',
  'G#': '\uE0A2',
  'A': '\uE0A2',
  'A#': '\uE0A2',
  'B': '\uE0A2'
}

export const ACCIDENTAL_SYMBOLS = {
  '#': '\uE262',
  'b': '\uE260'
}

