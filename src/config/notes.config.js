import { NOTE_NAMES } from '../shared/utils/constants'

export const INSTRUMENT_RANGE = {
  MIN_NOTE: 'E2',
  MAX_NOTE: 'E5',
  MIN_OCTAVE: 2,
  MAX_OCTAVE: 5
}

function noteToOrder(noteName) {
  const match = noteName.match(/^([A-G]#?)(\d+)$/)
  if (!match) return -1
  const [, note, octaveStr] = match
  const noteIndex = NOTE_NAMES.indexOf(note)
  const octave = parseInt(octaveStr, 10)
  return (octave + 1) * 12 + noteIndex
}

export const PLAYABLE_NOTES = (() => {
  const results = []
  for (let octave = INSTRUMENT_RANGE.MIN_OCTAVE; octave <= INSTRUMENT_RANGE.MAX_OCTAVE; octave++) {
    for (const note of NOTE_NAMES) {
      const noteName = `${note}${octave}`
      const order = noteToOrder(noteName)
      if (order >= noteToOrder(INSTRUMENT_RANGE.MIN_NOTE) && 
          order <= noteToOrder(INSTRUMENT_RANGE.MAX_NOTE)) {
        results.push(noteName)
      }
    }
  }
  return results
})()


