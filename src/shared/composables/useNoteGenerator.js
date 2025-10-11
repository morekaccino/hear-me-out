import { ref } from 'vue'
import { NOTE_NAMES } from '../utils/constants'
import { PLAYABLE_NOTES, INSTRUMENT_RANGE } from '../../config/notes.config'

export function useNoteGenerator() {
  const noteIdCounter = ref(0)

  function noteToOrder(noteName) {
    const match = noteName.match(/^([A-G]#?)(\d+)$/)
    if (!match) return -1
    const [, note, octaveStr] = match
    const noteIndex = NOTE_NAMES.indexOf(note)
    const octave = parseInt(octaveStr, 10)
    return (octave + 1) * 12 + noteIndex
  }

  function generateNote() {
    const value = PLAYABLE_NOTES[Math.floor(Math.random() * PLAYABLE_NOTES.length)]
    return {
      id: noteIdCounter.value++,
      value,
      isFlipped: false
    }
  }

  function generateNoteForOctaves(allowedOctaves = null) {
    let pool = PLAYABLE_NOTES
    
    if (Array.isArray(allowedOctaves) && allowedOctaves.length > 0) {
      pool = PLAYABLE_NOTES.filter(noteName => {
        const match = noteName.match(/\d+$/)
        if (!match) return false
        return allowedOctaves.includes(parseInt(match[0], 10))
      })
    }
    
    const value = pool[Math.floor(Math.random() * pool.length)]
    return {
      id: noteIdCounter.value++,
      value,
      isFlipped: false
    }
  }

  function generateStack(size = 5) {
    return Array.from({ length: size }, () => generateNote())
  }

  function generateStackForOctaves(size = 5, allowedOctaves = null) {
    return Array.from({ length: size }, () => generateNoteForOctaves(allowedOctaves))
  }

  return {
    generateNote,
    generateNoteForOctaves,
    generateStack,
    generateStackForOctaves
  }
}

