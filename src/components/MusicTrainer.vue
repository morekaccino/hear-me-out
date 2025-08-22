<template>
  <div class="trainer-app">
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
import { ref, onMounted, onUnmounted, nextTick } from 'vue'
import Stack from './Stack.vue'
import { usePitchDetection } from '../composables/usePitchDetection.js'
import { useNoteGenerator } from '../composables/useNoteGenerator.js'

// Composables
const { isListening, startMicrophone, stopMicrophone } = usePitchDetection()
const { generateNote, generateStack } = useNoteGenerator()

// State
const noteStack = ref([])
const stackRef = ref(null)

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

function onNoteDetected(detectedNote) {
  const currentNote = noteStack.value[noteStack.value.length - 1]?.value
  
  if (detectedNote === currentNote) {
    swipeRight()
  } else if (detectedNote && detectedNote !== currentNote) {
    swipeLeft()
  }
}

// Lifecycle
onMounted(async () => {
  initializeStack()
  await startMicrophone(onNoteDetected)
})

onUnmounted(() => {
  stopMicrophone()
  if (stackRef.value) {
    stackRef.value.destroyGestures()
  }
})
</script>

<style scoped>
.trainer-app {
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
</style>
