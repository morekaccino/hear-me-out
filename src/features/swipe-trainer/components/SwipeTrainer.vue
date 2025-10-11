<template>
  <div class="trainer-app">
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

    <CardStack
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
import CardStack from './CardStack.vue'
import { usePitchDetection } from '../../../shared/composables/usePitchDetection'
import { useNoteGenerator } from '../../../shared/composables/useNoteGenerator'
import { DETECTION_TIMING } from '../../../shared/utils/constants'

const { isListening, startMicrophone, stopMicrophone, latestPitch, latestClarity, latestNote } = usePitchDetection()
const { generateNote, generateStack } = useNoteGenerator()

const noteStack = ref([])
const stackRef = ref(null)
const isDetecting = ref(false)
const showSuccess = ref(false)
const detectedNote = ref('')
let detectionTimeout = null
let successTimeout = null

const currentNote = computed(() => {
  const topCard = noteStack.value[noteStack.value.length - 1]
  return topCard ? topCard.value : ''
})

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
  nextCard()
}

function swipeLeft() {
  nextCard()
}

function nextCard() {
  if (stackRef.value) {
    stackRef.value.destroyGestures()
  }
  
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
  if (stackRef.value?.cardRefs) {
    const topCardIndex = noteStack.value.length - 1
    stackRef.value.cardRefs.forEach((cardRef, index) => {
      if (cardRef && index === topCardIndex) {
        cardRef.renderNotation?.()
      }
    })
  }
}

function onNoteDetected(detectedNoteValue) {
  detectedNote.value = detectedNoteValue
  isDetecting.value = true
  
  if (detectionTimeout) {
    clearTimeout(detectionTimeout)
  }
  
  detectionTimeout = setTimeout(() => {
    isDetecting.value = false
    detectedNote.value = ''
  }, DETECTION_TIMING.DETECTION_RESET_MS)
  
  if (detectedNoteValue === currentNote.value) {
    showSuccess.value = true
    
    if (successTimeout) {
      clearTimeout(successTimeout)
    }
    
    setTimeout(() => {
      if (stackRef.value) {
        stackRef.value.triggerAutoSwipeRight()
        showSuccess.value = false
      } else {
        swipeRight()
        showSuccess.value = false
      }
    }, DETECTION_TIMING.SUCCESS_DELAY_MS)
    
    successTimeout = setTimeout(() => {
      showSuccess.value = false
    }, DETECTION_TIMING.SUCCESS_RESET_MS)
  }
}

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
  background: linear-gradient(135deg, var(--primary-color) 0%, var(--secondary-color) 100%);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: var(--spacing-sm);
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  overflow: hidden;
  user-select: none;
  -webkit-user-select: none;
}

.mic-status {
  position: fixed;
  top: var(--spacing-lg);
  left: 50%;
  transform: translateX(-50%);
  background: var(--bg-glass-light);
  backdrop-filter: blur(10px);
  border: 2px solid var(--border-glass);
  border-radius: var(--radius-full);
  padding: var(--spacing-sm) var(--spacing-lg);
  display: flex;
  align-items: center;
  gap: var(--spacing-sm);
  color: var(--text-light);
  z-index: 1000;
  transition: all var(--transition-normal);
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
  font-size: var(--font-size-base);
  text-align: center;
  flex: 1;
}

.detected-note {
  font-size: var(--font-size-sm);
  opacity: 0.8;
  background: rgba(255, 255, 255, 0.2);
  padding: 0.3rem 0.8rem;
  border-radius: var(--radius-md);
  margin-left: var(--spacing-xs);
}

@media (max-width: 768px) {
  .mic-status {
    top: var(--spacing-sm);
    padding: 0.8rem 1.5rem;
    min-width: 250px;
    font-size: var(--font-size-sm);
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
    padding: 0.6rem var(--spacing-sm);
    min-width: 200px;
    font-size: 0.8rem;
    flex-direction: column;
    gap: var(--spacing-xs);
  }
  
  .detected-note {
    margin-left: 0;
    margin-top: 0.2rem;
  }
}
</style>

