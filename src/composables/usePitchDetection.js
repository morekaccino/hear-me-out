import { ref } from 'vue'
import { PitchDetectorWrapper, frequencyToNoteName } from '../utils/pitchDetection.js'

export function usePitchDetection() {
  const isListening = ref(false)
  const latestPitch = ref(null)
  const latestClarity = ref(0)
  const latestNote = ref('')

  // Internal detector (Pitchy-based)
  let detector = null
  let onNoteDetectedCallback = null

  // Debounce/consensus controls
  let lastDetectedNote = null
  let lastDetectionTime = 0
  let detectionHistory = []
  const DETECTION_COOLDOWN = 120 // ms (slightly faster feedback)
  const CONFIDENCE_THRESHOLD = 1 // require only 1 solid hit
  const HISTORY_WINDOW_MS = 700 // widen window a bit for stability

  function addToDetectionHistory(note) {
    const now = Date.now()

    // Trim old entries
    detectionHistory = detectionHistory.filter(d => now - d.timestamp < 1000)

    detectionHistory.push({ note, timestamp: now })

    const recent = detectionHistory.filter(d => now - d.timestamp < HISTORY_WINDOW_MS)
    const groups = {}
    for (const d of recent) {
      groups[d.note] = (groups[d.note] || 0) + 1
    }

    let winner = null
    let max = 0
    for (const [n, c] of Object.entries(groups)) {
      if (c > max) { max = c; winner = n }
    }

    if (winner && max >= CONFIDENCE_THRESHOLD) {
      const elapsed = now - lastDetectionTime
      if (winner !== lastDetectedNote || elapsed > DETECTION_COOLDOWN) {
        lastDetectedNote = winner
        lastDetectionTime = now
        onNoteDetectedCallback?.(winner)
        detectionHistory = []
      }
    }
  }

  async function startMicrophone(onNoteDetected) {
    onNoteDetectedCallback = onNoteDetected

    detector = new PitchDetectorWrapper()
    const ok = await detector.initialize()
    if (!ok) {
      throw new Error('Failed to initialize microphone or pitch detector')
    }

  detector.startListening((pitch, noteName, clarity) => {
      // Consider slightly lower clarity to capture softer instruments/voices
      if (pitch && clarity && clarity > 0.6 && pitch > 50 && pitch < 2000) {
        // Ensure consistent note naming
    const name = noteName || frequencyToNoteName(pitch)
    latestPitch.value = pitch
    latestClarity.value = clarity
    latestNote.value = name
    if (name) addToDetectionHistory(name)
      }
    })

    isListening.value = true
  }

  function stopMicrophone() {
    try {
      detector?.stopListening()
      detector?.cleanup()
    } finally {
      detector = null
      isListening.value = false
      onNoteDetectedCallback = null
      lastDetectedNote = null
      lastDetectionTime = 0
      detectionHistory = []
    }
  }

  return {
    isListening,
    startMicrophone,
  stopMicrophone,
  latestPitch,
  latestClarity,
  latestNote
  }
}
