import { PitchDetector } from 'pitchy'

// Note names array for conversion
const NOTE_NAMES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

// Convert frequency to MIDI note number
export function frequencyToMidi(frequency) {
  return 69 + 12 * Math.log2(frequency / 440)
}

// Convert MIDI note number to note name with octave
export function midiToNoteName(midi) {
  const noteIndex = Math.round(midi) % 12
  const octave = Math.floor(Math.round(midi) / 12) - 1
  return NOTE_NAMES[noteIndex] + octave
}

// Convert frequency directly to note name
export function frequencyToNoteName(frequency) {
  const midi = frequencyToMidi(frequency)
  return midiToNoteName(midi)
}

// Calculate cents difference between two frequencies
export function centsDifference(freq1, freq2) {
  return 1200 * Math.log2(freq2 / freq1)
}

// Check if two notes match within tolerance (in cents)
export function notesMatch(detectedFreq, targetFreq, toleranceCents = 50) {
  const diff = Math.abs(centsDifference(detectedFreq, targetFreq))
  return diff <= toleranceCents
}

// Convert note name to frequency
export function noteNameToFrequency(noteName) {
  // Parse note name (e.g., "A4", "C#3")
  const match = noteName.match(/^([A-G]#?)(\d+)$/)
  if (!match) return null
  
  const [, note, octave] = match
  const noteIndex = NOTE_NAMES.indexOf(note)
  if (noteIndex === -1) return null
  
  const midi = noteIndex + (parseInt(octave) + 1) * 12
  return 440 * Math.pow(2, (midi - 69) / 12)
}

// SMuFL note head Unicode characters for whole notes
export const NOTE_SYMBOLS = {
  'C': '\uE0A2',   // noteheadWhole
  'C#': '\uE0A2',  // noteheadWhole
  'D': '\uE0A2',   // noteheadWhole
  'D#': '\uE0A2',  // noteheadWhole
  'E': '\uE0A2',   // noteheadWhole
  'F': '\uE0A2',   // noteheadWhole
  'F#': '\uE0A2',  // noteheadWhole
  'G': '\uE0A2',   // noteheadWhole
  'G#': '\uE0A2',  // noteheadWhole
  'A': '\uE0A2',   // noteheadWhole
  'A#': '\uE0A2',  // noteheadWhole
  'B': '\uE0A2'    // noteheadWhole
}

// Sharp and flat symbols
export const ACCIDENTAL_SYMBOLS = {
  '#': '\uE262',   // accidentalSharp
  'b': '\uE260'    // accidentalFlat
}

// Pitch detection class
export class PitchDetectorWrapper {
  constructor() {
    this.audioContext = null
    this.analyser = null
    this.microphone = null
    this.buffer = null
    this.detector = null
    this.isListening = false
    this.onPitchDetected = null
    this.sampleRate = 44100
  }

  async initialize() {
    try {
      // Get microphone access
      const stream = await navigator.mediaDevices.getUserMedia({ 
        audio: {
          echoCancellation: false,
          autoGainControl: false,
          noiseSuppression: false,
          sampleRate: 44100
        } 
      })
      
      // Create audio context
      this.audioContext = new (window.AudioContext || window.webkitAudioContext)()
      this.sampleRate = this.audioContext.sampleRate
      this.analyser = this.audioContext.createAnalyser()
      this.microphone = this.audioContext.createMediaStreamSource(stream)
      
      // Configure analyser
      this.analyser.fftSize = 4096
      this.analyser.smoothingTimeConstant = 0.8
      
      // Connect microphone to analyser
      this.microphone.connect(this.analyser)
      
      // Create buffer for audio data
      this.buffer = new Float32Array(this.analyser.fftSize)
      
      // Initialize Pitchy detector
      this.detector = PitchDetector.forFloat32Array(this.analyser.fftSize)
      this.detector.clarityThreshold = 0.8
      this.detector.minVolumeDecibels = -40 // Minimum volume threshold
      
      return true
    } catch (error) {
      console.error('Failed to initialize pitch detector:', error)
      return false
    }
  }

  startListening(callback) {
    if (!this.analyser || !this.detector) {
      console.error('Pitch detector not initialized')
      return
    }

    this.isListening = true
    this.onPitchDetected = callback

    const detectPitch = () => {
      if (!this.isListening) return

      // Get time domain data
      this.analyser.getFloatTimeDomainData(this.buffer)
      
      // Detect pitch using Pitchy
      const [pitch, clarity] = this.detector.findPitch(this.buffer, this.sampleRate)
      
      // Only report pitch if clarity is good enough and frequency is in reasonable range
      if (clarity > 0.8 && pitch > 80 && pitch < 2000) {
        const noteName = frequencyToNoteName(pitch)
        if (this.onPitchDetected) {
          this.onPitchDetected(pitch, noteName, clarity)
        }
      }

      // Continue detection
      requestAnimationFrame(detectPitch)
    }

    detectPitch()
  }

  stopListening() {
    this.isListening = false
    this.onPitchDetected = null
  }

  cleanup() {
    this.stopListening()
    
    if (this.microphone) {
      this.microphone.disconnect()
    }
    
    if (this.audioContext) {
      this.audioContext.close()
    }
  }
}
