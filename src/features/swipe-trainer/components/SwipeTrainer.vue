<template>
  <div class="trainer-app">
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
import { ref, onMounted, onUnmounted, nextTick } from 'vue'
import CardStack from './CardStack.vue'
import { usePitchDetection } from '../../../shared/composables/usePitchDetection'
import { useNoteGenerator } from '../../../shared/composables/useNoteGenerator'
import { useLeitnerSystem } from '../../../shared/composables/useLeitnerSystem'
import { DETECTION_TIMING } from '../../../shared/utils/constants'

const { startMicrophone, stopMicrophone } = usePitchDetection()
const { generateNote, generateStack } = useNoteGenerator()
const noteStack = ref([])
const stackRef = ref(null)
const detectedNote = ref('')
let detectionTimeout = null
let successTimeout = null

function getCurrentNote() {
  const topCard = noteStack.value[noteStack.value.length - 1]
  return topCard ? topCard.value : ''
}

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
  const topCard = noteStack.value[noteStack.value.length - 1]
  if (topCard) {
    markCorrect()
  }
  nextCard()
}

function swipeLeft() {
  const topCard = noteStack.value[noteStack.value.length - 1]
  if (topCard) {
    markIncorrect()
  }
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
  
  if (sessionComplete.value) {
    handleSessionComplete()
    return
  }
  
  const newCard = loadNextCard()
  if (newCard) {
    noteStack.value.unshift(newCard)
  }
  
  nextTick(() => {
    renderVisibleCards()
    if (stackRef.value) {
      stackRef.value.setupGestures()
    }
  })
}

function handleSessionComplete() {
  console.log('Session complete!', sessionStats.value)
  const result = startNewSession()
  console.log('New session started:', result)
  initializeStack()
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
  
  if (detectionTimeout) {
    clearTimeout(detectionTimeout)
  }
  
  detectionTimeout = setTimeout(() => {
    detectedNote.value = ''
  }, DETECTION_TIMING.DETECTION_RESET_MS)
  
  if (detectedNoteValue === getCurrentNote()) {
    if (successTimeout) {
      clearTimeout(successTimeout)
    }
    
    setTimeout(() => {
      if (stackRef.value) {
        stackRef.value.triggerAutoSwipeRight()
      } else {
        swipeRight()
        nextCard()
        showSuccess.value = false
      }
    }, DETECTION_TIMING.SUCCESS_DELAY_MS)
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

.leitner-stats {
  position: fixed;
  bottom: var(--spacing-lg);
  left: 50%;
  transform: translateX(-50%);
  background: var(--bg-glass-light);
  backdrop-filter: blur(10px);
  border: 2px solid var(--border-glass);
  border-radius: var(--radius-full);
  padding: var(--spacing-sm) var(--spacing-lg);
  display: flex;
  gap: var(--spacing-lg);
  color: var(--text-light);
  z-index: 1000;
  transition: all var(--transition-normal);
}

.stat-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.2rem;
}

.stat-label {
  font-size: 0.75rem;
  opacity: 0.8;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.stat-value {
  font-size: 1.25rem;
  font-weight: bold;
}

.stat-value.correct {
  color: var(--success-color, #4CAF50);
}

.stat-value.incorrect {
  color: var(--error-color, #f44336);
}

@media (max-width: 768px) {
  .leitner-stats {
    bottom: var(--spacing-sm);
    padding: 0.6rem var(--spacing-md);
    gap: var(--spacing-md);
  }
  
  .stat-label {
    font-size: 0.65rem;
  }
  
  .stat-value {
    font-size: 1rem;
  }
}

@media (max-width: 480px) {
  .leitner-stats {
    bottom: 0.5rem;
    padding: 0.5rem var(--spacing-sm);
    gap: var(--spacing-sm);
  }
  
  .stat-label {
    font-size: 0.6rem;
  }
  
  .stat-value {
    font-size: 0.9rem;
  }
}

.swipe-hints {
  position: fixed;
  top: 50%;
  left: 0;
  right: 0;
  transform: translateY(-50%);
  display: flex;
  justify-content: space-between;
  padding: 0 var(--spacing-lg);
  pointer-events: none;
  z-index: 5;
}

.hint {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(5px);
  padding: 0.8rem 1.2rem;
  border-radius: var(--radius-full);
  color: var(--text-light);
  font-weight: 500;
  opacity: 0.6;
  transition: opacity var(--transition-normal);
}

.hint:hover {
  opacity: 0.8;
}

.hint-icon {
  font-size: 1.5rem;
}

.hint-text {
  font-size: 0.9rem;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.hint-left {
  border: 2px solid rgba(244, 67, 54, 0.5);
}

.hint-right {
  border: 2px solid rgba(76, 175, 80, 0.5);
}

@media (max-width: 768px) {
  .swipe-hints {
    padding: 0 var(--spacing-sm);
  }
  
  .hint {
    padding: 0.6rem 1rem;
  }
  
  .hint-icon {
    font-size: 1.2rem;
  }
  
  .hint-text {
    font-size: 0.8rem;
  }
}

@media (max-width: 480px) {
  .hint-text {
    display: none;
  }
  
  .hint {
    padding: 0.8rem;
  }
}
</style>

