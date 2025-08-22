import { ref } from 'vue'

export function useNoteGenerator() {
  const noteIdCounter = ref(0)
  
  // Note data
  const notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
  const octaves = [3, 4, 5, 6]

  function generateNote() {
    const randomNote = notes[Math.floor(Math.random() * notes.length)]
    const randomOctave = octaves[Math.floor(Math.random() * octaves.length)]
    return {
      id: noteIdCounter.value++,
      value: randomNote + randomOctave,
      isFlipped: false
    }
  }

  function generateStack(size = 5) {
    const stack = []
    for (let i = 0; i < size; i++) {
      stack.push(generateNote())
    }
    return stack
  }

  return {
    generateNote,
    generateStack
  }
}
