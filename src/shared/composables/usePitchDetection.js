import { ref } from 'vue'
import { PitchDetectionService } from '../services/audio/PitchDetectionService'
import { frequencyToNoteName } from '../utils/noteConversion'
import { PITCH_DETECTION, DETECTION_TIMING } from '../utils/constants'

export function usePitchDetection() {
  const isListening = ref(false)
  const latestPitch = ref(null)
  const latestClarity = ref(0)
  const latestNote = ref('')

  let detector = null
  let onNoteDetectedCallback = null

  let lastDetectedNote = null
  let lastDetectionTime = 0
  let detectionHistory = []

  let lockedNote = null
  let requireNoteOff = false
  let refractoryUntil = 0
  let silenceFrames = 0

  function addToDetectionHistory(note) {
    const now = Date.now()

    detectionHistory = detectionHistory.filter(d => now - d.timestamp < 1000)
    detectionHistory.push({ note, timestamp: now })

    const recent = detectionHistory.filter(d => 
      now - d.timestamp < DETECTION_TIMING.HISTORY_WINDOW_MS
    )
    
    const groups = {}
    for (const d of recent) {
      groups[d.note] = (groups[d.note] || 0) + 1
    }

    let winner = null
    let max = 0
    for (const [n, c] of Object.entries(groups)) {
      if (c > max) {
        max = c
        winner = n
      }
    }

    if (winner && max >= DETECTION_TIMING.CONFIDENCE_THRESHOLD) {
      const elapsed = now - lastDetectionTime
      if (winner !== lastDetectedNote || elapsed > DETECTION_TIMING.COOLDOWN_MS) {
        lastDetectedNote = winner
        lastDetectionTime = now
        onNoteDetectedCallback?.(winner)
        
        lockedNote = winner
        requireNoteOff = true
        refractoryUntil = now + DETECTION_TIMING.REFRACTORY_MS
        detectionHistory = []
      }
    }
  }

  async function startMicrophone(onNoteDetected) {
    onNoteDetectedCallback = onNoteDetected

    detector = new PitchDetectionService()
    const initialized = await detector.initialize()
    
    if (!initialized) {
      throw new Error('Failed to initialize microphone or pitch detector')
    }

    detector.startListening((pitch, noteName, clarity) => {
      const now = Date.now()
      const safeClarity = typeof clarity === 'number' ? clarity : 0

      if (safeClarity <= PITCH_DETECTION.SILENCE_CLARITY) {
        silenceFrames++
      } else {
        silenceFrames = 0
      }

      if (typeof pitch === 'number') {
        latestPitch.value = pitch
      }
      latestClarity.value = safeClarity
      if (pitch) {
        latestNote.value = (noteName || frequencyToNoteName(pitch)) || ''
      }

      const isSolid = pitch && 
                      safeClarity > PITCH_DETECTION.MIN_CLARITY && 
                      pitch > PITCH_DETECTION.MIN_FREQUENCY && 
                      pitch < PITCH_DETECTION.MAX_FREQUENCY
      
      if (!isSolid) return

      const name = noteName || frequencyToNoteName(pitch)
      if (!name) return

      if (now < refractoryUntil) return

      if (requireNoteOff && lockedNote) {
        const noteChanged = name !== lockedNote
        const silentEnough = silenceFrames >= PITCH_DETECTION.SILENCE_FRAMES_TO_REARM
        
        if (!noteChanged && !silentEnough) return
        
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

