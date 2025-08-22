<template>
  <div class="app">
    <h1>🎵 Music Note Trainer</h1>
    <div class="note-display">
      <div v-if="displayMode === 'symbol'" class="staff-notation">
        <div class="staff-container">
          <!-- Treble clef -->
          <div class="treble-clef">�</div>
          
          <!-- Staff with positioned note -->
          <div class="staff-area">
            <!-- 5 staff lines -->
            <div class="staff-line" v-for="n in 5" :key="n" :style="{ top: (n-1) * 20 + 'px' }"></div>
            
            <!-- Positioned note -->
            <div class="note-position" :style="{ top: getNoteVerticalPosition() + 'px' }">
              <!-- Accidental (sharp/flat) if needed -->
              <span v-if="hasAccidental()" class="accidental">{{ getAccidentalSymbol() }}</span>
              <!-- Note head -->
              <span class="note-head">𝅘𝅥</span>
              <!-- Ledger lines for notes outside staff -->
              <div v-for="ledger in getLedgerLines()" :key="ledger" 
                   class="ledger-line" 
                   :style="{ top: ledger + 'px' }"></div>
            </div>
          </div>
          
          <!-- Note name label -->
          <div class="note-label">{{ currentNote }}</div>
        </div>
      </div>
      
      <div v-else class="note-letter">
        {{ currentNote }}
      </div>
    </div>
    
    <div class="controls">
      <button @click="toggleMode" class="mode-btn">
        {{ displayMode === 'symbol' ? 'Switch to Letters' : 'Switch to Staff' }}
      </button>
      <button @click="newNote" class="new-note-btn">New Note</button>
      <button @click="toggleMic" class="mic-btn" :class="{ active: isListening }">
        {{ isListening ? 'Stop' : 'Start' }} Microphone
      </button>
    </div>

    <div class="status">
      {{ statusMessage }}
    </div>

    <div class="score">
      Score: {{ score }}/{{ attempts }}
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'

// State
const displayMode = ref('letter') // 'symbol' or 'letter'
const currentNote = ref('A4')
const isListening = ref(false)
const statusMessage = ref('Click "Start Microphone" to begin')
const score = ref(0)
const attempts = ref(0)

// Note data
const notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
const octaves = [3, 4, 5, 6]

// Note positions on treble clef (pixels from top, where 0 is top of staff area)
// Staff lines are at: 0, 20, 40, 60, 80 pixels
const notePositions = {
  // Octave 6 (above staff)
  'A6': -30, 'B6': -20, 'C6': -10,
  // Octave 5 (on staff)
  'D6': -10, 'E6': 0, 'F6': 10, 'G6': 20, 'A6': 30, 'B6': 40,
  'C5': 50, 'D5': 40, 'E5': 30, 'F5': 20, 'G5': 10, 'A5': 0, 'B5': -10,
  // Octave 4 (on and below staff)
  'C4': 90, 'D4': 80, 'E4': 70, 'F4': 60, 'G4': 50, 'A4': 40, 'B4': 30,
  // Octave 3 (below staff)
  'C3': 110, 'D3': 100, 'E3': 90, 'F3': 100, 'G3': 90, 'A3': 80, 'B3': 70
}

// Audio context for microphone
let audioContext = null
let analyser = null
let microphone = null

// Meyda analyzer
let meydaAnalyzer = null

// Methods
function toggleMode() {
  displayMode.value = displayMode.value === 'symbol' ? 'letter' : 'symbol'
}

function newNote() {
  const randomNote = notes[Math.floor(Math.random() * notes.length)]
  const randomOctave = octaves[Math.floor(Math.random() * octaves.length)]
  currentNote.value = randomNote + randomOctave
  statusMessage.value = isListening.value ? 'Play the note!' : 'Click "Start Microphone" to begin'
}

function hasAccidental() {
  return currentNote.value.includes('#') || currentNote.value.includes('b')
}

function getAccidentalSymbol() {
  if (currentNote.value.includes('#')) return '♯'
  if (currentNote.value.includes('b')) return '♭'
  return ''
}

function getNoteVerticalPosition() {
  const baseNote = currentNote.value.replace(/[#b]/, '') // Remove accidentals
  return notePositions[baseNote] || 40 // Default to middle of staff
}

function getLedgerLines() {
  const position = getNoteVerticalPosition()
  const lines = []
  
  // Add ledger lines above staff (for high notes)
  if (position < 0) {
    for (let i = -10; i >= position - 5; i -= 20) {
      lines.push(i)
    }
  }
  
  // Add ledger lines below staff (for low notes)
  if (position > 80) {
    for (let i = 100; i <= position + 5; i += 20) {
      lines.push(i)
    }
  }
  
  return lines
}

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

async function toggleMic() {
  if (!isListening.value) {
    try {
      // Import Meyda dynamically
      const Meyda = (await import('meyda')).default
      
      // Get microphone access
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      
      // Create audio context
      audioContext = new (window.AudioContext || window.webkitAudioContext)()
      const source = audioContext.createMediaStreamSource(stream)
      
      // Create analyser
      analyser = audioContext.createAnalyser()
      analyser.fftSize = 2048
      source.connect(analyser)
      
      // Configure Meyda
      meydaAnalyzer = Meyda.createMeydaAnalyzer({
        audioContext: audioContext,
        source: source,
        bufferSize: 2048,
        featureExtractors: ['fundamentalFrequency'],
        callback: (features) => {
          if (features.fundamentalFrequency && features.fundamentalFrequency > 80 && features.fundamentalFrequency < 2000) {
            const detectedNote = frequencyToNote(features.fundamentalFrequency)
            
            if (detectedNote === currentNote.value) {
              statusMessage.value = `Correct! You played ${detectedNote} 🎉`
              score.value++
              attempts.value++
              
              // Auto-generate new note after success
              setTimeout(() => {
                newNote()
              }, 1500)
            } else if (detectedNote) {
              statusMessage.value = `Detected: ${detectedNote} - Try ${currentNote.value}`
            }
          }
        }
      })
      
      meydaAnalyzer.start()
      isListening.value = true
      statusMessage.value = 'Listening... Play the note!'
      
    } catch (error) {
      console.error('Microphone error:', error)
      statusMessage.value = 'Microphone access denied or failed'
    }
  } else {
    // Stop listening
    if (meydaAnalyzer) {
      meydaAnalyzer.stop()
    }
    if (audioContext) {
      audioContext.close()
    }
    isListening.value = false
    statusMessage.value = 'Stopped listening'
  }
}

// Lifecycle
onMounted(() => {
  newNote()
})

onUnmounted(() => {
  if (meydaAnalyzer) {
    meydaAnalyzer.stop()
  }
  if (audioContext) {
    audioContext.close()
  }
})
</script>

<style scoped>
.app {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 2rem;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}

h1 {
  font-size: 3rem;
  margin-bottom: 2rem;
  text-align: center;
}

.note-display {
  margin: 2rem 0;
  text-align: center;
  min-height: 250px;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* Staff notation */
.staff-notation {
  background: rgba(255, 255, 255, 0.95);
  border-radius: 20px;
  padding: 3rem 4rem;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.2);
  backdrop-filter: blur(10px);
  color: #333;
  min-width: 500px;
}

.staff-container {
  display: flex;
  align-items: center;
  gap: 2rem;
  position: relative;
}

.treble-clef {
  font-family: 'Bravura', serif;
  font-size: 6rem;
  color: #333;
  line-height: 1;
  margin-top: -1rem;
}

.staff-area {
  position: relative;
  width: 300px;
  height: 120px;
  flex: 1;
}

.staff-line {
  position: absolute;
  left: 0;
  right: 0;
  height: 2px;
  background: #333;
  border-radius: 1px;
}

.note-position {
  position: absolute;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.accidental {
  font-family: 'Bravura', serif;
  font-size: 2.5rem;
  color: #333;
  margin-right: 0.2rem;
}

.note-head {
  font-family: 'Bravura', serif;
  font-size: 2.5rem;
  color: #333;
  line-height: 1;
}

.ledger-line {
  position: absolute;
  left: -15px;
  right: -15px;
  height: 2px;
  background: #333;
  border-radius: 1px;
}

.note-label {
  position: absolute;
  bottom: -2.5rem;
  left: 50%;
  transform: translateX(-50%);
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  font-size: 1.2rem;
  color: #666;
  font-weight: 500;
}

/* Letter Mode */
.note-letter {
  font-size: 6rem;
  font-weight: bold;
  margin: 1rem;
  text-shadow: 0 4px 8px rgba(0,0,0,0.3);
  background: rgba(255, 255, 255, 0.1);
  padding: 2rem 3rem;
  border-radius: 20px;
  backdrop-filter: blur(10px);
}

.controls {
  display: flex;
  gap: 1rem;
  margin: 2rem 0;
  flex-wrap: wrap;
  justify-content: center;
}

button {
  padding: 1rem 2rem;
  font-size: 1rem;
  border: none;
  border-radius: 25px;
  background: rgba(255, 255, 255, 0.2);
  color: white;
  cursor: pointer;
  transition: all 0.3s;
  backdrop-filter: blur(10px);
  font-weight: 500;
}

button:hover {
  background: rgba(255, 255, 255, 0.3);
  transform: translateY(-2px);
}

.mic-btn.active {
  background: #4CAF50;
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.7; }
}

.status {
  font-size: 1.5rem;
  text-align: center;
  margin: 2rem 0;
  padding: 1rem 2rem;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 20px;
  backdrop-filter: blur(10px);
  max-width: 600px;
  line-height: 1.4;
}

.score {
  font-size: 1.2rem;
  font-weight: bold;
  background: rgba(255, 255, 255, 0.1);
  padding: 1rem 2rem;
  border-radius: 15px;
  backdrop-filter: blur(10px);
}

/* Responsive Design */
@media (max-width: 768px) {
  h1 {
    font-size: 2rem;
  }
  
  .staff-notation {
    padding: 2rem;
    min-width: 350px;
  }
  
  .staff-container {
    gap: 1rem;
  }
  
  .treble-clef {
    font-size: 4rem;
  }
  
  .staff-area {
    width: 200px;
    height: 100px;
  }
  
  .note-head {
    font-size: 2rem;
  }
  
  .accidental {
    font-size: 2rem;
  }
  
  .note-letter {
    font-size: 4rem;
    padding: 1.5rem 2rem;
  }
  
  .controls {
    flex-direction: column;
    align-items: center;
  }
  
  button {
    width: 200px;
  }
  
  .status {
    font-size: 1.2rem;
    padding: 0.8rem 1.5rem;
  }
}

@media (max-width: 480px) {
  .staff-notation {
    padding: 1.5rem;
    min-width: 300px;
  }
  
  .treble-clef {
    font-size: 3rem;
  }
  
  .staff-area {
    width: 150px;
    height: 80px;
  }
  
  .note-head {
    font-size: 1.8rem;
  }
  
  .accidental {
    font-size: 1.5rem;
  }
  
  .note-letter {
    font-size: 3rem;
    padding: 1rem 1.5rem;
  }
}
</style>

<style scoped>
.app {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 2rem;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}

h1 {
  font-size: 3rem;
  margin-bottom: 2rem;
  text-align: center;
}

.note-display {
  margin: 2rem 0;
  text-align: center;
  min-height: 250px;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* Staff notation using Bravura font */
.staff-notation {
  background: rgba(255, 255, 255, 0.95);
  border-radius: 20px;
  padding: 3rem 4rem;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.2);
  backdrop-filter: blur(10px);
  color: #333;
  min-width: 400px;
}

.staff-container {
  font-family: 'Bravura', serif;
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 2rem;
  font-size: 4rem;
  line-height: 1;
}

.staff-lines .staff-symbol {
  color: #333;
  font-size: 6rem;
}

.clef .treble-clef {
  color: #333;
  font-size: 5rem;
  margin-right: 1rem;
}

.note-area {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  position: relative;
}

.accidental {
  color: #333;
  font-size: 3rem;
}

.note {
  color: #333;
  font-size: 4rem;
}

.note-label {
  position: absolute;
  bottom: -3rem;
  left: 50%;
  transform: translateX(-50%);
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  font-size: 1.2rem;
  color: #666;
  font-weight: 500;
}

/* Letter Mode */
.note-letter {
  font-size: 6rem;
  font-weight: bold;
  margin: 1rem;
  text-shadow: 0 4px 8px rgba(0,0,0,0.3);
  background: rgba(255, 255, 255, 0.1);
  padding: 2rem 3rem;
  border-radius: 20px;
  backdrop-filter: blur(10px);
}

.controls {
  display: flex;
  gap: 1rem;
  margin: 2rem 0;
  flex-wrap: wrap;
  justify-content: center;
}

button {
  padding: 1rem 2rem;
  font-size: 1rem;
  border: none;
  border-radius: 25px;
  background: rgba(255, 255, 255, 0.2);
  color: white;
  cursor: pointer;
  transition: all 0.3s;
  backdrop-filter: blur(10px);
  font-weight: 500;
}

button:hover {
  background: rgba(255, 255, 255, 0.3);
  transform: translateY(-2px);
}

.mic-btn.active {
  background: #4CAF50;
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.7; }
}

.status {
  font-size: 1.5rem;
  text-align: center;
  margin: 2rem 0;
  padding: 1rem 2rem;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 20px;
  backdrop-filter: blur(10px);
  max-width: 600px;
  line-height: 1.4;
}

.score {
  font-size: 1.2rem;
  font-weight: bold;
  background: rgba(255, 255, 255, 0.1);
  padding: 1rem 2rem;
  border-radius: 15px;
  backdrop-filter: blur(10px);
}

/* Responsive Design */
@media (max-width: 768px) {
  h1 {
    font-size: 2rem;
  }
  
  .staff-notation {
    padding: 2rem;
    min-width: 300px;
  }
  
  .staff-container {
    font-size: 3rem;
    gap: 1rem;
  }
  
  .clef .treble-clef {
    font-size: 4rem;
  }
  
  .staff-lines .staff-symbol {
    font-size: 4.5rem;
  }
  
  .note {
    font-size: 3rem;
  }
  
  .accidental {
    font-size: 2.5rem;
  }
  
  .note-letter {
    font-size: 4rem;
    padding: 1.5rem 2rem;
  }
  
  .controls {
    flex-direction: column;
    align-items: center;
  }
  
  button {
    width: 200px;
  }
  
  .status {
    font-size: 1.2rem;
    padding: 0.8rem 1.5rem;
  }
}

@media (max-width: 480px) {
  .staff-notation {
    padding: 1.5rem;
    min-width: 250px;
  }
  
  .staff-container {
    font-size: 2.5rem;
    gap: 0.5rem;
  }
  
  .clef .treble-clef {
    font-size: 3rem;
  }
  
  .staff-lines .staff-symbol {
    font-size: 3.5rem;
  }
  
  .note {
    font-size: 2.5rem;
  }
  
  .accidental {
    font-size: 2rem;
  }
  
  .note-letter {
    font-size: 3rem;
    padding: 1rem 1.5rem;
  }
}
</style>
