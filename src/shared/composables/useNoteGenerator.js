import { ref } from 'vue'
import { PLAYABLE_NOTES } from '../../config/notes.config'

export function useNoteGenerator() {
  const noteIdCounter = ref(0)

  function generateNote() {
    const value = PLAYABLE_NOTES[Math.floor(Math.random() * PLAYABLE_NOTES.length)]
    return {
      id: noteIdCounter.value++,
      value,
      isFlipped: false
    }
  }

  function generateStack(size = 5) {
    return Array.from({ length: size }, () => generateNote())
  }

  return {
    generateNote,
    generateStack
  }
}

