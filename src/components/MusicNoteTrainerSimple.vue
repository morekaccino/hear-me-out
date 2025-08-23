<template>
  <div class="music-trainer">
    <!-- Header -->
    <header class="trainer-header">
      <h1>🎵 Music Note Flashcard Trainer</h1>
      <div class="controls">
        <!-- Mode Toggle -->
        <div class="mode-toggle">
          <label class="toggle-label">
            <input 
              type="checkbox" 
              v-model="isSymbolMode"
              class="toggle-input"
            >
            <span class="toggle-slider"></span>
            <span class="toggle-text">
              {{ isSymbolMode ? 'Symbol Mode' : 'Letter Mode' }}
            </span>
          </label>
        </div>

        <!-- Microphone Control -->
        <button 
          @click="toggleMicrophone"
          :class="['mic-button', { active: isListening, error: micError }]"
          :disabled="!micInitialized && !micError"
        >
          <span class="mic-icon">🎤</span>
          {{ getMicButtonText() }}
        </button>
      </div>
    </header>

    <!-- Main Display Area -->
    <main class="trainer-main">
      <!-- Current Note Display -->
      <div class="note-display">
        <div v-if="isSymbolMode" class="note-symbol">
          {{ getNoteSymbol() }}
          <div v-if="hasAccidental()" class="accidental">
            {{ getAccidentalSymbol() }}
          </div>
        </div>
        <div v-else class="note-letter">
          {{ currentNote }}
        </div>
      </div>

      <!-- Status Display -->
      <div class="status-display">
        <div :class="['status-text', statusClass]">
          {{ statusText }}
        </div>
        
        <!-- Frequency Display (optional) -->
        <div v-if="showFrequency && detectedFrequency" class="frequency-display">
          Detected: {{ detectedFrequency.toFixed(1) }} Hz
          <br>
          Note: {{ detectedNote }}
        </div>
      </div>

      <!-- Score Display -->
      <div class="score-display">
        <div class="score-item">
          <span class="score-label">Correct:</span>
          <span class="score-value">{{ score.correct }}</span>
        </div>
        <div class="score-item">
          <span class="score-label">Total:</span>
          <span class="score-value">{{ score.total }}</span>
        </div>
        <div class="score-item">
          <span class="score-label">Accuracy:</span>
          <span class="score-value">{{ getAccuracyPercent() }}%</span>
        </div>
      </div>
    </main>

    <!-- Footer Controls -->
    <footer class="trainer-footer">
      <button @click="generateNewNote" class="new-note-button">
        New Note
      </button>
      
      <div class="options">
        <label class="checkbox-label">
          <input type="checkbox" v-model="showFrequency">
          Show Frequency
        </label>
      </div>
    </footer>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useNoteGenerator } from '../composables/useNoteGenerator.js'

const { generateNote: generateNoteLocal } = useNoteGenerator()

// Simple note symbols without external dependencies
const NOTE_SYMBOLS = {
  'C': '♪',   // Simple music note symbol
  'C#': '♪',  
  'D': '♪',   
  'D#': '♪',  
  'E': '♪',   
  'F': '♪',   
  'F#': '♪',  
  'G': '♪',   
  'G#': '♪',  
  'A': '♪',   
  'A#': '♪',  
  'B': '♪'    
}

const ACCIDENTAL_SYMBOLS = {
  '#': '♯',   // Sharp symbol
  'b': '♭'    // Flat symbol
}

// Reactive state
const isSymbolMode = ref(true)
const isListening = ref(false)
const micInitialized = ref(false)
const micError = ref(false)
const currentNote = ref('A4')
const statusText = ref('Click the microphone to start')
const statusClass = ref('neutral')
const detectedFrequency = ref(null)
const detectedNote = ref('')
const showFrequency = ref(false)

// Score tracking
const score = ref({
  correct: 0,
  total: 0
})

// Note range for random generation (C3 to C6)
const NOTE_RANGE = [
  'C3', 'C#3', 'D3', 'D#3', 'E3', 'F3', 'F#3', 'G3', 'G#3', 'A3', 'A#3', 'B3',
  'C4', 'C#4', 'D4', 'D#4', 'E4', 'F4', 'F#4', 'G4', 'G#4', 'A4', 'A#4', 'B4',
  'C5', 'C#5', 'D5', 'D#5', 'E5', 'F5', 'F#5', 'G5', 'G#5', 'A5', 'A#5', 'B5',
  'C6'
]

// Computed properties
const getAccuracyPercent = computed(() => {
  if (score.value.total === 0) return 0
  return Math.round((score.value.correct / score.value.total) * 100)
})

// Methods
function generateNewNote() {
  const n = generateNoteLocal()
  currentNote.value = n.value
  statusText.value = isListening.value ? 'Play the note!' : 'Click microphone to start'
  statusClass.value = 'neutral'
  detectedFrequency.value = null
  detectedNote.value = ''
}

function getNoteSymbol() {
  if (!currentNote.value) return ''
  const noteName = currentNote.value.replace(/\d+/, '') // Remove octave
  const baseNote = noteName.replace(/#|b/, '') // Remove accidental
  return NOTE_SYMBOLS[baseNote] || '♪'
}

function hasAccidental() {
  return currentNote.value.includes('#') || currentNote.value.includes('b')
}

function getAccidentalSymbol() {
  if (currentNote.value.includes('#')) return ACCIDENTAL_SYMBOLS['#']
  if (currentNote.value.includes('b')) return ACCIDENTAL_SYMBOLS['b']
  return ''
}

function getMicButtonText() {
  if (micError.value) return 'Mic Error'
  if (!micInitialized.value) return 'Initialize Mic'
  return isListening.value ? 'Stop Listening' : 'Start Listening'
}

function toggleMicrophone() {
  if (micError.value) {
    micError.value = false
    micInitialized.value = false
    statusText.value = 'Click Initialize Mic'
    return
  }

  if (!micInitialized.value) {
    // Simulate mic initialization
    micInitialized.value = true
    statusText.value = 'Microphone ready! Play the note.'
    return
  }

  if (isListening.value) {
    isListening.value = false
    statusText.value = 'Stopped listening'
    statusClass.value = 'neutral'
  } else {
    isListening.value = true
    statusText.value = 'Listening... Play the note!'
    statusClass.value = 'listening'
    
    // Simulate detection for demo
    setTimeout(() => {
      if (isListening.value) {
        score.value.correct++
        score.value.total++
        statusText.value = 'Correct! 🎉 (Demo Mode)'
        statusClass.value = 'success'
        
        setTimeout(() => {
          generateNewNote()
        }, 1500)
      }
    }, 3000)
  }
}

// Lifecycle
onMounted(() => {
  generateNewNote()
})
</script>

<style scoped>
.music-trainer {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}

.trainer-header {
  padding: 2rem;
  text-align: center;
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
}

.trainer-header h1 {
  margin: 0 0 2rem 0;
  font-size: 2.5rem;
  font-weight: 300;
}

.controls {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 2rem;
  flex-wrap: wrap;
}

/* Toggle Switch */
.mode-toggle {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.toggle-label {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  cursor: pointer;
}

.toggle-input {
  display: none;
}

.toggle-slider {
  width: 60px;
  height: 30px;
  background: rgba(255, 255, 255, 0.3);
  border-radius: 15px;
  position: relative;
  transition: background 0.3s;
}

.toggle-slider::before {
  content: '';
  position: absolute;
  width: 26px;
  height: 26px;
  border-radius: 50%;
  background: white;
  top: 2px;
  left: 2px;
  transition: transform 0.3s;
}

.toggle-input:checked + .toggle-slider {
  background: rgba(255, 255, 255, 0.5);
}

.toggle-input:checked + .toggle-slider::before {
  transform: translateX(30px);
}

.toggle-text {
  font-weight: 500;
}

/* Microphone Button */
.mic-button {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 1rem 2rem;
  background: rgba(255, 255, 255, 0.2);
  border: 2px solid rgba(255, 255, 255, 0.3);
  border-radius: 50px;
  color: white;
  cursor: pointer;
  transition: all 0.3s;
  font-size: 1rem;
  font-weight: 500;
}

.mic-button:hover {
  background: rgba(255, 255, 255, 0.3);
  transform: translateY(-2px);
}

.mic-button.active {
  background: #4CAF50;
  border-color: #4CAF50;
  animation: pulse 2s infinite;
}

.mic-button.error {
  background: #f44336;
  border-color: #f44336;
}

.mic-icon {
  font-size: 1.2rem;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.7; }
}

/* Main Content */
.trainer-main {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  padding: 2rem;
  gap: 3rem;
}

/* Note Display */
.note-display {
  text-align: center;
}

.note-symbol {
  font-family: 'Bravura', serif;
  font-size: 15rem;
  line-height: 1;
  position: relative;
  margin: 2rem 0;
}

.accidental {
  position: absolute;
  left: -3rem;
  top: 50%;
  transform: translateY(-50%);
  font-size: 8rem;
}

.note-letter {
  font-size: 10rem;
  font-weight: 300;
  margin: 2rem 0;
  text-shadow: 0 4px 8px rgba(0, 0, 0, 0.3);
}

/* Status Display */
.status-display {
  text-align: center;
}

.status-text {
  font-size: 1.5rem;
  font-weight: 500;
  margin-bottom: 1rem;
  padding: 1rem 2rem;
  border-radius: 25px;
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  transition: all 0.3s;
}

.status-text.neutral {
  background: rgba(255, 255, 255, 0.1);
}

.status-text.listening {
  background: rgba(33, 150, 243, 0.3);
  animation: pulse 2s infinite;
}

.status-text.success {
  background: rgba(76, 175, 80, 0.3);
  color: #4CAF50;
}

.frequency-display {
  font-size: 1rem;
  opacity: 0.8;
  background: rgba(0, 0, 0, 0.2);
  padding: 0.5rem 1rem;
  border-radius: 10px;
  display: inline-block;
}

/* Score Display */
.score-display {
  display: flex;
  gap: 2rem;
  justify-content: center;
  flex-wrap: wrap;
}

.score-item {
  text-align: center;
  background: rgba(255, 255, 255, 0.1);
  padding: 1rem 1.5rem;
  border-radius: 15px;
  backdrop-filter: blur(10px);
}

.score-label {
  display: block;
  font-size: 0.9rem;
  opacity: 0.8;
  margin-bottom: 0.5rem;
}

.score-value {
  display: block;
  font-size: 1.5rem;
  font-weight: 600;
}

/* Footer */
.trainer-footer {
  padding: 2rem;
  text-align: center;
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
}

.new-note-button {
  padding: 1rem 3rem;
  background: rgba(255, 255, 255, 0.2);
  border: 2px solid rgba(255, 255, 255, 0.3);
  border-radius: 50px;
  color: white;
  cursor: pointer;
  font-size: 1.1rem;
  font-weight: 500;
  margin-bottom: 1rem;
  transition: all 0.3s;
}

.new-note-button:hover {
  background: rgba(255, 255, 255, 0.3);
  transform: translateY(-2px);
}

.options {
  margin-top: 1rem;
}

.checkbox-label {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  cursor: pointer;
  opacity: 0.8;
}

.checkbox-label input[type="checkbox"] {
  transform: scale(1.2);
}

/* Responsive Design */
@media (max-width: 768px) {
  .trainer-header h1 {
    font-size: 2rem;
  }
  
  .controls {
    flex-direction: column;
    gap: 1rem;
  }
  
  .note-symbol {
    font-size: 10rem;
  }
  
  .accidental {
    font-size: 5rem;
    left: -2rem;
  }
  
  .note-letter {
    font-size: 6rem;
  }
  
  .score-display {
    gap: 1rem;
  }
  
  .score-item {
    padding: 0.8rem 1rem;
  }
}

@media (max-width: 480px) {
  .trainer-header {
    padding: 1rem;
  }
  
  .trainer-main {
    padding: 1rem;
    gap: 2rem;
  }
  
  .note-symbol {
    font-size: 8rem;
  }
  
  .note-letter {
    font-size: 5rem;
  }
  
  .status-text {
    font-size: 1.2rem;
    padding: 0.8rem 1.5rem;
  }
}
</style>
