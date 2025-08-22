import { ref } from 'vue'

export function usePitchDetection() {
  const isListening = ref(false)
  
  // Note data
  const notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
  
  // Audio context variables
  let audioContext = null
  let analyser = null
  let meydaAnalyzer = null

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

  async function startMicrophone(onNoteDetected) {
    try {
      const Meyda = (await import('meyda')).default
      
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      
      audioContext = new (window.AudioContext || window.webkitAudioContext)()
      const source = audioContext.createMediaStreamSource(stream)
      
      analyser = audioContext.createAnalyser()
      analyser.fftSize = 2048
      source.connect(analyser)
      
      meydaAnalyzer = Meyda.createMeydaAnalyzer({
        audioContext: audioContext,
        source: source,
        bufferSize: 2048,
        featureExtractors: ['fundamentalFrequency'],
        callback: (features) => {
          if (features.fundamentalFrequency && features.fundamentalFrequency > 80 && features.fundamentalFrequency < 2000) {
            const detectedNote = frequencyToNote(features.fundamentalFrequency)
            if (detectedNote && onNoteDetected) {
              onNoteDetected(detectedNote)
            }
          }
        }
      })
      
      meydaAnalyzer.start()
      isListening.value = true
      
    } catch (error) {
      console.error('Microphone error:', error)
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
  }

  return {
    isListening,
    startMicrophone,
    stopMicrophone
  }
}
