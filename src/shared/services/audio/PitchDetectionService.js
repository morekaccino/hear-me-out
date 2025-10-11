import { PitchDetector } from 'pitchy'
import { frequencyToNoteName } from '../../utils/noteConversion'
import { PITCH_DETECTION } from '../../utils/constants'

export class PitchDetectionService {
  constructor() {
    this.audioContext = null
    this.analyser = null
    this.microphone = null
    this.buffer = null
    this.detector = null
    this.isListening = false
    this.onPitchDetected = null
    this.sampleRate = PITCH_DETECTION.SAMPLE_RATE
  }

  async initialize() {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ 
        audio: {
          echoCancellation: false,
          autoGainControl: false,
          noiseSuppression: false,
          sampleRate: PITCH_DETECTION.SAMPLE_RATE
        } 
      })
      
      this.audioContext = new (window.AudioContext || window.webkitAudioContext)()
      this.sampleRate = this.audioContext.sampleRate
      this.analyser = this.audioContext.createAnalyser()
      this.microphone = this.audioContext.createMediaStreamSource(stream)
      
      this.analyser.fftSize = PITCH_DETECTION.FFT_SIZE
      this.analyser.smoothingTimeConstant = PITCH_DETECTION.SMOOTHING_TIME_CONSTANT
      
      this.microphone.connect(this.analyser)
      
      this.buffer = new Float32Array(this.analyser.fftSize)
      
      this.detector = PitchDetector.forFloat32Array(this.analyser.fftSize)
      this.detector.clarityThreshold = PITCH_DETECTION.CLARITY_THRESHOLD
      this.detector.minVolumeDecibels = PITCH_DETECTION.MIN_VOLUME_DECIBELS
      
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

      this.analyser.getFloatTimeDomainData(this.buffer)
      
      const [pitch, clarity] = this.detector.findPitch(this.buffer, this.sampleRate)
      
      if (clarity > PITCH_DETECTION.CLARITY_THRESHOLD && 
          pitch > PITCH_DETECTION.MIN_FREQUENCY && 
          pitch < PITCH_DETECTION.MAX_FREQUENCY) {
        const noteName = frequencyToNoteName(pitch)
        
        if (this.onPitchDetected) {
          this.onPitchDetected(pitch, noteName, clarity)
        }
      }

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

