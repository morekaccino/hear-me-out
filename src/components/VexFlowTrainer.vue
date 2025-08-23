<template>
  <div class="app">
    <div class="card-container">
      <div 
        v-for="(note, index) in noteStack" 
        :key="note.id"
        :class="['note-card', { 'top-card': index === noteStack.length - 1 }]"
        :style="{ 
          zIndex: noteStack.length - index,
          transform: index === noteStack.length - 1 
            ? cardTransform 
            : `translateY(${(noteStack.length - 1 - index) * 8}px) translateX(${(noteStack.length - 1 - index) * 4}px) scale(${1 - (noteStack.length - 1 - index) * 0.03}) rotate(${(noteStack.length - 1 - index) * 2}deg)`,
          opacity: index === noteStack.length - 1 ? 1 : (1 - (noteStack.length - 1 - index) * 0.15),
          visibility: index < noteStack.length - 3 ? 'hidden' : 'visible'
        }"
        @click="flipCard(index)"
        :ref="el => { if (el && index === noteStack.length - 1) topCardRef = el }"
      >
        <div class="card-content" :class="{ flipped: note.isFlipped }">
          <!-- Front: Staff notation -->
          <div class="card-front">
            <div ref="vexflowRefs" :data-note="note.value" class="vexflow-staff"></div>
          </div>
          
          <!-- Back: Letter -->
          <div class="card-back">
            <div class="note-letter">{{ note.value }}</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, nextTick, watch } from 'vue'
import Hammer from 'hammerjs'
import { useNoteGenerator } from '../composables/useNoteGenerator.js'
import { soundingToWritten, writtenToSounding, frequencyToNoteName } from '../utils/pitchDetection.js'

// State
const noteStack = ref([])
const currentCardIndex = ref(0)
const cardTransform = ref('')
const isListening = ref(false)
const startX = ref(0)
const isDragging = ref(false)
const isPointerDown = ref(false)
const vexflowRefs = ref([])
const cardRefs = ref([])
const topCardRef = ref(null)
let hammerInstance = null

// Note data
// We'll use the project's note generator for classical guitar range

// Audio context for microphone
let audioContext = null
let analyser = null
let meydaAnalyzer = null
let noteIdCounter = 0

// Methods
// Use useNoteGenerator to produce notes in E2..B5; instantiate generator
const { generateNote: generateNoteLocal, generateStack: generateStackLocal } = useNoteGenerator()

function initializeStack() {
  noteStack.value = [
  generateNoteLocal(),
  generateNoteLocal(),
  generateNoteLocal(),
  generateNoteLocal(),
  generateNoteLocal()
  ]
  console.debug('[VexFlowTrainer] initial stack', noteStack.value.map(n => n.value))
  nextTick(() => {
    // Only render the top 3 cards initially
    renderVisibleCards()
  })
}

function flipCard(index) {
  if (isDragging.value) return
  if (index === noteStack.value.length - 1) {
    noteStack.value[index].isFlipped = !noteStack.value[index].isFlipped
  }
}

function setupGestures() {
  if (topCardRef.value && !hammerInstance) {
    hammerInstance = new Hammer(topCardRef.value)
    
    // Enable swipe gestures
    hammerInstance.get('swipe').set({ direction: Hammer.DIRECTION_HORIZONTAL })
    hammerInstance.get('pan').set({ direction: Hammer.DIRECTION_HORIZONTAL })
    
    // Handle pan (drag) events
    hammerInstance.on('panstart', (e) => {
      isDragging.value = true
      startX.value = e.center.x
    })
    
    hammerInstance.on('panmove', (e) => {
      if (isDragging.value) {
        const deltaX = e.deltaX
        const rotation = deltaX / 10
        cardTransform.value = `translateX(${deltaX}px) rotate(${rotation}deg)`
      }
    })
    
    hammerInstance.on('panend', (e) => {
      const threshold = 120
      const deltaX = e.deltaX
      
      if (Math.abs(deltaX) > threshold) {
        if (deltaX > 0) {
          swipeRight()
        } else {
          swipeLeft()
        }
      } else {
        // Reset position
        cardTransform.value = ''
      }
      
      setTimeout(() => {
        isDragging.value = false
      }, 100)
    })
    
    // Handle swipe events as backup
    hammerInstance.on('swiperight', () => {
      if (!isDragging.value) {
        swipeRight()
      }
    })
    
    hammerInstance.on('swipeleft', () => {
      if (!isDragging.value) {
        swipeLeft()
      }
    })
  }
}

function destroyGestures() {
  if (hammerInstance) {
    hammerInstance.destroy()
    hammerInstance = null
  }
}

function getClientX(event) {
  return event.touches ? event.touches[0].clientX : event.clientX
}

function getFinalClientX(event) {
  return event.changedTouches ? event.changedTouches[0].clientX : event.clientX
}

function startSwipe(event, index) {
  if (index === noteStack.value.length - 1) {
    if (event.type === 'mousedown' && event.button !== 0) return
    
    startX.value = getClientX(event)
    isPointerDown.value = true
    isDragging.value = false
  }
}

function onSwipe(event, index) {
  if (index === noteStack.value.length - 1 && isPointerDown.value) {
    const currentX = getClientX(event)
    const deltaX = currentX - startX.value
    
    if (Math.abs(deltaX) > 10) {
      isDragging.value = true
    }
    
    cardTransform.value = `translateX(${deltaX}px) rotate(${deltaX / 20}deg)`
  }
}

function endSwipe(event, index) {
  if (index !== noteStack.value.length - 1 || !isPointerDown.value) return

  const finalX = getFinalClientX(event)
  const deltaX = finalX - startX.value
  const swipeThreshold = 100

  if (isDragging.value && Math.abs(deltaX) > swipeThreshold) {
    if (deltaX > 0) {
      swipeRight()
    } else {
      swipeLeft()
    }
  } else {
    cardTransform.value = ''
  }
  
  isPointerDown.value = false
  startX.value = 0
  setTimeout(() => {
    isDragging.value = false
  }, 50)
}

function swipeRight() {
  // Correct note - animate swipe right
  cardTransform.value = 'translateX(100vw) rotate(30deg)'
  setTimeout(() => {
    nextCard()
  }, 300)
}

function swipeLeft() {
  // Wrong note - animate swipe left
  cardTransform.value = 'translateX(-100vw) rotate(-30deg)'
  setTimeout(() => {
    nextCard()
  }, 300)
}

function nextCard() {
  // Remove top card and add new one
  destroyGestures()
  noteStack.value.pop()
  noteStack.value.unshift(generateNoteLocal())
  cardTransform.value = ''
  
  nextTick(() => {
    // Pre-render the new bottom card before it becomes visible
    renderVisibleCards()
    // Pre-load the next card that will be visible
    preloadNextCard()
    setupGestures()
  })
}

function preloadNextCard() {
  // Pre-render the card that will become the new top card
  const bottomCardIndex = 0
  const bottomCardElement = vexflowRefs.value[bottomCardIndex]
  if (bottomCardElement) {
    const noteValue = bottomCardElement.getAttribute('data-note')
    const isRendered = bottomCardElement.getAttribute('data-rendered')
    if (noteValue && !isRendered) {
      renderNotation(bottomCardElement, noteValue)
    }
  }
}

function noteToVexFlowKey(note) {
  // Safely parse the note and convert sounding -> written (written = sounding +1)
  const m = note.match(/^([A-G]#?)(-?\d+)$/)
  if (!m) return note
  const [, base, octStr] = m
  const written = soundingToWritten(`${base}${octStr}`)
  const wm = written.match(/^([A-G]#?)(-?\d+)$/)
  if (!wm) return `${base.toLowerCase()}/${octStr}`
  const [, wbase, woct] = wm
  return `${wbase.toLowerCase()}/${woct}`
}

async function renderNotation(element, noteValue) {
  if (!element) return

  try {
    const { Renderer, Stave, StaveNote, Voice, Formatter, Accidental } = await import('vexflow')

    // Clear previous content
    element.innerHTML = ''

    const renderer = new Renderer(element, Renderer.Backends.SVG)
    
    // Use fixed large dimensions and a massive scale
    const width = 800
    const height = 600
    const scale = 3.5 // Massively increased scale

    renderer.resize(width, height)
    const context = renderer.getContext()
    context.scale(scale, scale)

    // Center the stave in the new, larger coordinate system
    const staveWidth = 150
    const staveX = (width / scale - staveWidth) / 2
    const staveY = (height / scale - 100) / 2 // Center vertically
    
    const stave = new Stave(staveX, staveY, staveWidth)
    stave.addClef('treble')
    stave.setContext(context).draw()

  const vexNote = noteToVexFlowKey(noteValue)
  try { console.debug('[VexFlowTrainer] renderNotation', { noteValue, written: soundingToWritten(noteValue), vexNote, staveX, staveY, staveWidth, width, height, scale }) } catch(e){}
    const note = new StaveNote({
      clef: 'treble',
      keys: [vexNote],
      duration: 'w'
    })

    if (noteValue.includes('#')) {
      note.addModifier(new Accidental('#'), 0)
    } else if (noteValue.includes('b')) {
      note.addModifier(new Accidental('b'), 0)
    }

    const voice = new Voice({ num_beats: 1, beat_value: 4 })
    voice.setStrict(false)
    voice.addTickables([note])

    new Formatter().joinVoices([voice]).format([voice], staveWidth)
    voice.draw(context, stave)

    // Mark as rendered to prevent re-rendering
    element.setAttribute('data-rendered', 'true')
    // Append a small debug caption showing sounding vs written pitch
    try {
      const written = soundingToWritten(noteValue)
      const caption = document.createElement('div')
      caption.className = 'note-debug'
      caption.textContent = `sounding: ${noteValue} — written: ${written}`
      // Remove previous caption if present
      const prev = element.querySelector('.note-debug')
      if (prev) prev.remove()
      element.appendChild(caption)
    } catch (e) {
      // ignore debug rendering errors
    }

  } catch (error) {
    console.error('VexFlow rendering error:', error)
  }
}

function renderVisibleCards() {
  // Only render the top 3 cards to avoid lag and visual artifacts
  const visibleCardCount = Math.min(3, noteStack.value.length)
  const startIndex = noteStack.value.length - visibleCardCount
  
  vexflowRefs.value.forEach((element, index) => {
    if (element && index >= startIndex) {
      const noteValue = element.getAttribute('data-note')
      const isRendered = element.getAttribute('data-rendered')
      if (noteValue && !isRendered) {
        renderNotation(element, noteValue)
      }
    } else if (element) {
      // Clear non-visible cards to prevent rendering artifacts
      element.innerHTML = ''
      element.removeAttribute('data-rendered')
    }
  })
}

function renderAllNotations() {
  vexflowRefs.value.forEach((element, index) => {
    if (element) {
      const noteValue = element.getAttribute('data-note')
      if (noteValue) {
        renderNotation(element, noteValue)
      }
    }
  })
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

async function startMicrophone() {
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
        const f = features.fundamentalFrequency
        if (f && f > 80 && f < 2000) {
          const detectedNote = frequencyToNote(f)
          const currentNote = noteStack.value[noteStack.value.length - 1]?.value
          try { console.debug('[VexFlowTrainer][Meyda] fundFreq ->', { f, detectedNote, currentNote }) } catch(e){}
          if (detectedNote === currentNote) {
            swipeRight()
          } else if (detectedNote && detectedNote !== currentNote) {
            swipeLeft()
          }
        } else {
          try { console.debug('[VexFlowTrainer][Meyda] ignored freq', { f }) } catch(e){}
        }
      }
    })
    
    meydaAnalyzer.start()
    isListening.value = true
    
  } catch (error) {
    console.error('Microphone error:', error)
  }
}

// Lifecycle
onMounted(async () => {
  initializeStack()
  await startMicrophone()
  nextTick(() => {
    setupGestures()
    // Preload the next card for smooth transitions
    preloadNextCard()
  })
})

onUnmounted(() => {
  if (meydaAnalyzer) {
    meydaAnalyzer.stop()
  }
  if (audioContext) {
    audioContext.close()
  }
  destroyGestures()
})
</script>

<style scoped>
.app {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1rem;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  overflow: hidden;
  user-select: none;
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
}

.card-container {
  position: relative;
  width: 90vw;
  height: 90vh;
  max-width: 800px;
  max-height: 900px;
  perspective: 1000px;
  user-select: none;
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
}

.note-card {
  position: absolute;
  width: 100%;
  height: 100%;
  cursor: pointer;
  transition: transform 0.3s ease-out, box-shadow 0.3s ease-out, opacity 0.3s ease-out;
  border-radius: 20px;
  box-shadow: 
    0 8px 32px rgba(0, 0, 0, 0.2),
    0 4px 16px rgba(0, 0, 0, 0.1),
    0 2px 8px rgba(0, 0, 0, 0.05);
  user-select: none;
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  -webkit-touch-callout: none;
  -webkit-tap-highlight-color: transparent;
  border: 1px solid rgba(255, 255, 255, 0.2);
  transform-origin: center bottom;
}

.top-card {
  z-index: 10 !important;
  box-shadow: 
    0 16px 48px rgba(0, 0, 0, 0.3),
    0 8px 24px rgba(0, 0, 0, 0.2),
    0 4px 12px rgba(0, 0, 0, 0.1);
}

.card-content {
  position: relative;
  width: 100%;
  height: 100%;
  transition: transform 0.6s;
  transform-style: preserve-3d;
  border-radius: 20px;
}

.card-content.flipped {
  transform: rotateY(180deg);
}

.card-front,
.card-back {
  position: absolute;
  width: 100%;
  height: 100%;
  backface-visibility: hidden;
  border-radius: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
  padding: 0;
  margin: 0;
  user-select: none;
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  -webkit-touch-callout: none;
  -webkit-tap-highlight-color: transparent;
  border: 1px solid rgba(255, 255, 255, 0.3);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.4);
}

.card-back {
  transform: rotateY(180deg);
  background: rgba(255, 255, 255, 0.98);
}

.vexflow-staff {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  user-select: none;
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  pointer-events: none;
  overflow: hidden;
  position: relative;
}

.vexflow-staff :deep(svg) {
  background: transparent;
  width: 100%;
  height: auto;
  max-width: 100%;
  user-select: none;
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  pointer-events: none;
}

.note-debug {
  position: absolute;
  bottom: 8px;
  left: 12px;
  font-size: 0.9rem;
  color: rgba(0,0,0,0.6);
  background: rgba(255,255,255,0.9);
  padding: 4px 8px;
  border-radius: 6px;
  pointer-events: none;
}

.note-letter {
  font-size: 12rem;
  font-weight: bold;
  color: #333;
  text-shadow: 0 4px 8px rgba(0,0,0,0.1);
  user-select: none;
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  pointer-events: none;
}

/* Mobile responsive */
@media (max-width: 768px) {
  .card-container {
    width: 95vw;
    height: 85vh;
    max-width: 600px;
    max-height: 800px;
  }
  
  .note-letter {
    font-size: 8rem;
  }
}

@media (max-width: 480px) {
  .card-container {
    width: 95vw;
    height: 80vh;
    max-width: 400px;
    max-height: 700px;
  }
  
  .note-letter {
    font-size: 6rem;
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
  padding: 1rem;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}

.note-display {
  margin: 0;
  text-align: center;
  width: 100%;
  max-width: 700px;
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* Staff notation with VexFlow */
.staff-notation {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
}

.vexflow-container {
  display: flex;
  justify-content: center;
  align-items: center;
}

.vexflow-staff {
  /* VexFlow will inject SVG here */
  width: 100%;
  height: auto;
  display: flex;
  justify-content: center;
  align-items: center;
  overflow: visible;
}

/* VexFlow SVG styling */
:deep(.vexflow-staff svg) {
  background: transparent;
  width: 100%;
  height: auto;
  max-width: 100%;
  display: block;
  margin: 0 auto;
}

.note-label {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  font-size: clamp(1rem, 3vw, 1.2rem);
  color: #fff;
  font-weight: 500;
  margin-top: 0.5rem;
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
  gap: 0.5rem;
  margin: 1rem 0;
  flex-wrap: wrap;
  justify-content: center;
  width: 100%;
  max-width: 500px;
}

button {
  padding: 0.8rem 1.5rem;
  font-size: clamp(0.9rem, 2.5vw, 1rem);
  border: none;
  border-radius: 25px;
  background: rgba(255, 255, 255, 0.2);
  color: white;
  cursor: pointer;
  transition: all 0.3s;
  backdrop-filter: blur(10px);
  font-weight: 500;
  flex: 1;
  min-width: 140px;
  max-width: 200px;
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
  font-size: clamp(1.1rem, 3vw, 1.5rem);
  text-align: center;
  margin: 1rem 0;
  padding: 0.8rem 1.5rem;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 20px;
  backdrop-filter: blur(10px);
  max-width: 90%;
  line-height: 1.4;
}

.score {
  font-size: clamp(1rem, 2.5vw, 1.2rem);
  font-weight: bold;
  background: rgba(255, 255, 255, 0.1);
  padding: 0.8rem 1.5rem;
  border-radius: 15px;
  backdrop-filter: blur(10px);
}

/* Responsive Design */
@media (max-width: 768px) {
  h1 {
    font-size: 2rem;
  }
  
  .staff-notation {
    padding: 1.5rem;
  }
  
  .vexflow-staff {
    min-width: 350px;
    min-height: 120px;
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
    padding: 1rem;
  }
  
  .vexflow-staff {
    min-width: 300px;
    min-height: 100px;
  }
  
  .note-letter {
    font-size: 3rem;
    padding: 1rem 1.5rem;
  }
}
</style>
