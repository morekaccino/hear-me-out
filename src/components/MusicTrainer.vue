<template>
  <div class="trainer-app">
    <!-- Microphone Status Indicator -->
  <div class="mic-status" :class="{ 
      listening: isListening, 
      detecting: isDetecting,
      success: showSuccess 
    }">
      <div class="mic-icon">🎤</div>
      <div class="status-text">
        <span v-if="!isListening">Microphone Initializing...</span>
        <span v-else-if="isDetecting">Note Detected!</span>
        <span v-else>Listening for: {{ currentNote }}</span>
      </div>
      <div v-if="detectedNote" class="detected-note">
        Detected: {{ detectedNote }}
      </div>
      <div v-if="latestPitch" class="detected-note" style="opacity:.7">
        Live: {{ latestNote }} ({{ latestPitch.toFixed(1) }} Hz · {{ (latestClarity*100).toFixed(0) }}%)
      </div>
    </div>

    <Stack
      :notes="noteStack"
      @flip="flipCard"
      @swipe-right="swipeRight"
      @swipe-left="swipeLeft"
      ref="stackRef"
    />
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, nextTick, computed } from 'vue'
import Stack from './Stack.vue'
import { usePitchDetection } from '../composables/usePitchDetection.js'
import { useNoteGenerator } from '../composables/useNoteGenerator.js'

// Composables
const { isListening, startMicrophone, stopMicrophone, latestPitch, latestClarity, latestNote } = usePitchDetection()
const { generateNote, generateStack } = useNoteGenerator()

// State
const noteStack = ref([])
const stackRef = ref(null)
const isDetecting = ref(false)
const showSuccess = ref(false)
const detectedNote = ref('')
let detectionTimeout = null
let successTimeout = null

// Computed
const currentNote = computed(() => {
  const topCard = noteStack.value[noteStack.value.length - 1]
  return topCard ? topCard.value : ''
})

// Methods
function initializeStack() {
  noteStack.value = generateStack(5)
  nextTick(() => {
    renderVisibleCards()
  })
}

function flipCard(index) {
  if (index === noteStack.value.length - 1) {
    noteStack.value[index].isFlipped = !noteStack.value[index].isFlipped
  }
}

function swipeRight() {
  // Correct note - move to next card
  nextCard()
}

function swipeLeft() {
  // Wrong note - move to next card
  nextCard()
}

function nextCard() {
  // Remove top card and add new one
  if (stackRef.value) {
    stackRef.value.destroyGestures()
  }
  
  // Reset the flip state of the card being removed
  const topCard = noteStack.value[noteStack.value.length - 1]
  if (topCard) {
    topCard.isFlipped = false
  }
  
  noteStack.value.pop()
  noteStack.value.unshift(generateNote())
  
  nextTick(() => {
    renderVisibleCards()
    if (stackRef.value) {
      stackRef.value.setupGestures()
    }
  })
}

function renderVisibleCards() {
  // Only render the top card to prevent scrambling
  if (stackRef.value?.cardRefs) {
    const topCardIndex = noteStack.value.length - 1
    stackRef.value.cardRefs.forEach((cardRef, index) => {
      if (cardRef && index === topCardIndex) {
        cardRef.renderNotation?.()
      }
    })
  }
}

function preloadNextCard() {
  // Prepare the next card that will become the top card after swipe
  if (stackRef.value?.cardRefs) {
    const nextCardIndex = noteStack.value.length - 2
    const nextCardRef = stackRef.value.cardRefs[nextCardIndex]
    if (nextCardRef) {
      // The next card will become top card after swipe, so it will auto-render
      // No need to pre-render here to avoid conflicts
    }
  }
}

function onNoteDetected(detectedNoteValue) {
  detectedNote.value = detectedNoteValue
  isDetecting.value = true
  
  // Clear previous timeout
  if (detectionTimeout) {
    clearTimeout(detectionTimeout)
  }
  
  // Reset detection indicator after 800ms
  detectionTimeout = setTimeout(() => {
    isDetecting.value = false
    detectedNote.value = ''
  }, 800)
  
  // Strict match: require exact note + octave (e.g., C4 only matches C4)
  if (detectedNoteValue === currentNote.value) {
    showSuccess.value = true
    
    // Clear previous success timeout
    if (successTimeout) {
      clearTimeout(successTimeout)
    }
    
    // Auto swipe right after a short delay to show success feedback
    setTimeout(() => {
      if (stackRef.value) {
        stackRef.value.triggerAutoSwipeRight()
        showSuccess.value = false
      } else {
        swipeRight()
        showSuccess.value = false
      }
  }, 600)
    
    // Reset success indicator
    successTimeout = setTimeout(() => {
      showSuccess.value = false
    }, 1500)
  }
}

// Lifecycle
onMounted(async () => {
  initializeStack()
  
  try {
    await startMicrophone(onNoteDetected)
  } catch (error) {
    console.error('Failed to start microphone:', error)
  }
})

onUnmounted(() => {
  stopMicrophone()
  if (stackRef.value) {
    stackRef.value.destroyGestures()
  }
  if (detectionTimeout) {
    clearTimeout(detectionTimeout)
  }
  if (successTimeout) {
    clearTimeout(successTimeout)
  }
})
</script>

<style scoped>
.trainer-app {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  flex-direction: column;
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

/* Microphone Status Indicator */
.mic-status {
  position: fixed;
  top: 2rem;
  left: 50%;
  transform: translateX(-50%);
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  border: 2px solid rgba(255, 255, 255, 0.2);
  border-radius: 50px;
  padding: 1rem 2rem;
  display: flex;
  align-items: center;
  gap: 1rem;
  color: white;
  z-index: 1000;
  transition: all 0.3s ease;
  min-width: 280px;
  justify-content: center;
}

.mic-status.listening {
  border-color: rgba(76, 175, 80, 0.5);
  background: rgba(76, 175, 80, 0.2);
  animation: pulse 2s infinite;
}

.mic-status.detecting {
  border-color: rgba(33, 150, 243, 0.8);
  background: rgba(33, 150, 243, 0.3);
  transform: translateX(-50%) scale(1.05);
}

.mic-status.success {
  border-color: rgba(76, 175, 80, 0.8);
  background: rgba(76, 175, 80, 0.4);
  transform: translateX(-50%) scale(1.1);
}

.mic-icon {
  font-size: 1.5rem;
  animation: bounce 2s infinite;
}

.mic-status.listening .mic-icon {
  animation: bounce 1s infinite;
}

.mic-status.detecting .mic-icon {
  animation: bounce 0.5s infinite;
}

.status-text {
  font-weight: 500;
  font-size: 1rem;
  text-align: center;
  flex: 1;
}

.detected-note {
  font-size: 0.9rem;
  opacity: 0.8;
  background: rgba(255, 255, 255, 0.2);
  padding: 0.3rem 0.8rem;
  border-radius: 15px;
  margin-left: 0.5rem;
}

@keyframes pulse {
  0%, 100% {
    opacity: 1;
    transform: translateX(-50%) scale(1);
  }
  50% {
    opacity: 0.8;
    transform: translateX(-50%) scale(1.02);
  }
}

@keyframes bounce {
  0%, 100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-5px);
  }
}

/* Mobile responsive */
@media (max-width: 768px) {
  .mic-status {
    top: 1rem;
    padding: 0.8rem 1.5rem;
    min-width: 250px;
    font-size: 0.9rem;
  }
  
  .mic-icon {
    font-size: 1.2rem;
  }
  
  .detected-note {
    font-size: 0.8rem;
    padding: 0.2rem 0.6rem;
  }
}

@media (max-width: 480px) {
  .mic-status {
    top: 0.5rem;
    padding: 0.6rem 1rem;
    min-width: 200px;
    font-size: 0.8rem;
    flex-direction: column;
    gap: 0.5rem;
  }
  
  .detected-note {
    margin-left: 0;
    margin-top: 0.2rem;
  }
}
</style>
