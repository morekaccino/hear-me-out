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

export function shiftNoteOctave(noteName, octaveShift = 0) {
  const match = noteName.match(/^([A-G]#?)(-?\d+)$/)
  if (!match) return noteName
  const [, base, octaveStr] = match
  const octave = parseInt(octaveStr, 10) + octaveShift
  return `${base}${octave}`
}

