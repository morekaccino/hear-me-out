import { ref } from 'vue'

export function useNoteGenerator() {
  const noteIdCounter = ref(0)
  
  // Note data constrained to classical guitar range (E2 to B5)
  const notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
  // Build the full playable pool within the instrument bounds
  const playableNotes = (() => {
    const results = []
  const minOct = 2 // E2
  const maxOct = 5 // Limit to octave 5 (sounding B5 max)
    for (let oct = minOct; oct <= maxOct; oct++) {
      for (const n of notes) {
        const name = `${n}${oct}`
        // Include only notes within E2 (inclusive) to B5 (inclusive)
    const order = noteOrder(name)
  // Keep pool within E2..E5 (sounding)
  if (order >= noteOrder('E2') && order <= noteOrder('E5')) {
          results.push(name)
        }
      }
    }
    return results
  })()

  function noteOrder(name) {
    // Convert note name to an absolute index for range comparisons
    const m = name.match(/^([A-G]#?)(\d+)$/)
    if (!m) return -1
    const [, ltr, octStr] = m
    const idx = notes.indexOf(ltr)
    const oct = parseInt(octStr)
    return (oct + 1) * 12 + idx // MIDI-like ordering
  }

  function generateNote() {
    const value = playableNotes[Math.floor(Math.random() * playableNotes.length)]
    return {
      id: noteIdCounter.value++,
      value,
      isFlipped: false
    }
  }

  // Generate a single note constrained to allowedOctaves (array of octave numbers).
  function generateNoteForOctaves(allowedOctaves = null) {
    let pool = playableNotes
    if (Array.isArray(allowedOctaves) && allowedOctaves.length > 0) {
      pool = playableNotes.filter(n => {
        const m = n.match(/\d+$/)
        if (!m) return false
        return allowedOctaves.includes(parseInt(m[0]))
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
    const stack = []
    for (let i = 0; i < size; i++) {
      stack.push(generateNote())
    }
    return stack
  }

  function generateStackForOctaves(size = 5, allowedOctaves = null) {
    const stack = []
    for (let i = 0; i < size; i++) stack.push(generateNoteForOctaves(allowedOctaves))
    return stack
  }

  return {
  generateNote,
  generateNoteForOctaves,
  generateStack,
  generateStackForOctaves
  }
}
