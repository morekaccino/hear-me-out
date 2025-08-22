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

  // Gating to avoid repeated triggers on a sustained note
  let lockedNote = null
  let requireNoteOff = false
  let refractoryUntil = 0
  let silenceFrames = 0
  const SILENCE_CLARITY = 0.4
  const SILENCE_FRAMES_TO_REARM = 6 // ~100ms at 60fps
  const REFRACTORY_MS = 700

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
  // After a successful detection, lock to this note and require note-off
  lockedNote = winner
  requireNoteOff = true
  refractoryUntil = now + REFRACTORY_MS
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
      const now = Date.now()
      const safeClarity = typeof clarity === 'number' ? clarity : 0

      // Track silence frames to detect note-off
      if (safeClarity <= SILENCE_CLARITY) {
        silenceFrames++
      } else {
        silenceFrames = 0
      }

      // Update live telemetry
      if (typeof pitch === 'number') {
        latestPitch.value = pitch
      }
      latestClarity.value = safeClarity
      if (pitch) {
        latestNote.value = (noteName || frequencyToNoteName(pitch)) || ''
      }

      // Basic validity check for a solid detection
      const solid = pitch && safeClarity > 0.6 && pitch > 50 && pitch < 2000
      if (!solid) {
        return
      }

      const name = noteName || frequencyToNoteName(pitch)
      if (!name) return

      // Refractory period after a successful hit
      if (now < refractoryUntil) {
        return
      }

      // If we require note-off, enforce it until silence or different note
      if (requireNoteOff && lockedNote) {
        const noteChanged = name !== lockedNote
        const silentEnough = silenceFrames >= SILENCE_FRAMES_TO_REARM
        if (!noteChanged && !silentEnough) {
          return
        }
        // Re-arm once conditions met
        requireNoteOff = false
        lockedNote = null
      }

      addToDetectionHistory(name)
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
