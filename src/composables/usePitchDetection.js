import { ref } from 'vue'

export function usePitchDetection() {
  const isListening = ref(false)
  
  // Note data
  const notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
  
  // Audio context variables
  let audioContext = null
  let analyser = null
  let meydaAnalyzer = null
  let onNoteDetectedCallback = null
  
  // Detection settings
  let lastDetectedNote = null
  let lastDetectionTime = 0
  let detectionHistory = []
  const DETECTION_COOLDOWN = 200 // ms
  const CONFIDENCE_THRESHOLD = 3 // number of consistent detections needed

  function frequencyToNote(frequency) {
    const A4 = 440
    const C0 = A4 * Math.pow(2, -4.75)
    
    if (frequency > C0) {
      const h = Math.round(12 * Math.log2(frequency / C0))
      const octave = Math.floor(h / 12)
      const n = h % 12
      return notes[n] + octave
    }
    return null
  }

  function addToDetectionHistory(note) {
    const now = Date.now()
    
    // Remove old detections (older than 1 second)
    detectionHistory = detectionHistory.filter(detection => 
      now - detection.timestamp < 1000
    )
    
    // Add new detection
    detectionHistory.push({
      note,
      timestamp: now
    })
    
    // Check for consistent detections
    const recentDetections = detectionHistory.filter(detection =>
      now - detection.timestamp < 500 // Look at last 500ms
    )
    
    const noteGroups = {}
    recentDetections.forEach(detection => {
      if (!noteGroups[detection.note]) {
        noteGroups[detection.note] = 0
      }
      noteGroups[detection.note]++
    })
    
    // Find the most detected note
    let mostDetectedNote = null
    let maxCount = 0
    
    for (const [note, count] of Object.entries(noteGroups)) {
      if (count > maxCount) {
        maxCount = count
        mostDetectedNote = note
      }
    }
    
    // If we have enough consistent detections, trigger callback
    if (maxCount >= CONFIDENCE_THRESHOLD && mostDetectedNote) {
      const timeSinceLastDetection = now - lastDetectionTime
      
      // Prevent too frequent detections of the same note
      if (mostDetectedNote !== lastDetectedNote || timeSinceLastDetection > DETECTION_COOLDOWN) {
        lastDetectedNote = mostDetectedNote
        lastDetectionTime = now
        
        if (onNoteDetectedCallback) {
          onNoteDetectedCallback(mostDetectedNote)
        }
        
        // Clear history after successful detection
        detectionHistory = []
      }
    }
  }

  async function startMicrophone(onNoteDetected) {
    try {
      onNoteDetectedCallback = onNoteDetected
      
      const Meyda = (await import('meyda')).default
      
      const stream = await navigator.mediaDevices.getUserMedia({ 
        audio: {
          echoCancellation: false,
          autoGainControl: false,
          noiseSuppression: false,
          sampleRate: 44100
        }
      })
      
      audioContext = new (window.AudioContext || window.webkitAudioContext)()
      const source = audioContext.createMediaStreamSource(stream)
      
      analyser = audioContext.createAnalyser()
      analyser.fftSize = 4096 // Increased for better frequency resolution
      analyser.smoothingTimeConstant = 0.3
      source.connect(analyser)
      
      meydaAnalyzer = Meyda.createMeydaAnalyzer({
        audioContext: audioContext,
        source: source,
        bufferSize: 4096,
        featureExtractors: ['fundamentalFrequency'],
        callback: (features) => {
          if (features.fundamentalFrequency && 
              features.fundamentalFrequency > 80 && 
              features.fundamentalFrequency < 2000) {
            
            const detectedNote = frequencyToNote(features.fundamentalFrequency)
            if (detectedNote) {
              addToDetectionHistory(detectedNote)
            }
          }
        }
      })
      
      meydaAnalyzer.start()
      isListening.value = true
      
    } catch (error) {
      console.error('Microphone error:', error)
      throw error
    }
  }

  function stopMicrophone() {
    if (meydaAnalyzer) {
      meydaAnalyzer.stop()
      meydaAnalyzer = null
    }
    if (audioContext) {
      audioContext.close()
      audioContext = null
    }
    
    isListening.value = false
    onNoteDetectedCallback = null
    lastDetectedNote = null
    lastDetectionTime = 0
    detectionHistory = []
  }

  return {
    isListening,
    startMicrophone,
    stopMicrophone
  }
}
