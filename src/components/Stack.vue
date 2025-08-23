<template>
  <div class="card-container" ref="containerRef">
    <Card
      v-for="(note, index) in notes" 
      :key="note.id"
      :note="note"
      :is-top-card="index === notes.length - 1"
      :card-style="getCardStyle(index)"
      @flip="flipCard(index)"
      @card-ref="handleCardRef($event, index)"
      :ref="el => setCardRef(el, index)"
    />
  </div>
</template>

<script setup>
import { ref, computed, nextTick, onMounted, onUnmounted } from 'vue'
import Card from './Card.vue'

const props = defineProps({
  notes: {
    type: Array,
    required: true
  }
})

const emit = defineEmits(['flip', 'swipeRight', 'swipeLeft'])

const containerRef = ref(null)
const cardTransform = ref('')
const isDragging = ref(false)
const cardRefs = ref([])
const topCardRef = ref(null)

// Unified gesture handling state
let startX = 0
let startY = 0
let startTime = 0
let isPointerDown = false
let hasMovedDuringPress = false
let initialTouchTarget = null

// Unified helper functions
function getEventCoords(event) {
  if (event.touches && event.touches.length > 0) {
    return {
      x: event.touches[0].clientX,
      y: event.touches[0].clientY
    }
  } else if (event.changedTouches && event.changedTouches.length > 0) {
    return {
      x: event.changedTouches[0].clientX,
      y: event.changedTouches[0].clientY
    }
  } else {
    return {
      x: event.clientX,
      y: event.clientY
    }
  }
}

function isTopCard(event) {
  const target = event.target
  if (!topCardRef.value) return false
  
  return topCardRef.value.contains(target)
}

function preventDefault(event) {
  event.preventDefault()
  event.stopPropagation()
}

// Unified gesture handlers
function handlePointerStart(event) {
  // Only handle left mouse button or touch
  if (event.type === 'mousedown' && event.button !== 0) return
  
  // Only handle gestures on the top card
  if (!isTopCard(event)) return
  
  const coords = getEventCoords(event)
  startX = coords.x
  startY = coords.y
  startTime = Date.now()
  isPointerDown = true
  hasMovedDuringPress = false
  initialTouchTarget = event.target
  
  // Reset any flip state when starting a gesture
  const topCard = props.notes[props.notes.length - 1]
  if (topCard && topCard.isFlipped) {
    topCard.isFlipped = false
  }
  
  // Prevent default behavior for touch events to avoid conflicts
  if (event.type === 'touchstart') {
    preventDefault(event)
  }
}

function handlePointerMove(event) {
  if (!isPointerDown) return
  
  const coords = getEventCoords(event)
  const deltaX = coords.x - startX
  const deltaY = coords.y - startY
  
  // Mark as moved if we've moved more than 5px
  if (Math.abs(deltaX) > 5 || Math.abs(deltaY) > 5) {
    hasMovedDuringPress = true
  }
  
  // Only start dragging for horizontal movements > 10px
  if (Math.abs(deltaX) > 10 && Math.abs(deltaX) > Math.abs(deltaY)) {
    if (!isDragging.value) {
      isDragging.value = true
    }
    
    const rotation = deltaX / 20
    cardTransform.value = `translateX(${deltaX}px) rotate(${rotation}deg)`
    
    // Prevent default behavior during drag
    preventDefault(event)
  }
}

function handlePointerEnd(event) {
  if (!isPointerDown) return
  
  const coords = getEventCoords(event)
  const deltaX = coords.x - startX
  const deltaY = coords.y - startY
  const deltaTime = Date.now() - startTime
  const distance = Math.sqrt(deltaX * deltaX + deltaY * deltaY)
  
  isPointerDown = false
  
  // Handle swipe gestures
  if (isDragging.value && Math.abs(deltaX) > 100) {
    if (deltaX > 0) {
      handleSwipeRight()
    } else {
      handleSwipeLeft()
    }
  }
  // Handle tap/click - must be quick, small movement, and on same target
  else if (!hasMovedDuringPress && 
           distance < 10 && 
           deltaTime < 300 && 
           event.target === initialTouchTarget) {
    
    // Reset position first
    cardTransform.value = ''
    isDragging.value = false
    
    // Then emit flip
    setTimeout(() => {
      const topCardIndex = props.notes.length - 1
      emit('flip', topCardIndex)
    }, 50)
  }
  // Reset position for incomplete gestures
  else {
    cardTransform.value = ''
    
    // Reset dragging state with slight delay for large movements
    if (Math.abs(deltaX) < 50) {
      isDragging.value = false
    } else {
      setTimeout(() => {
        isDragging.value = false
      }, 100)
    }
  }
  
  // Reset state
  startX = 0
  startY = 0
  startTime = 0
  hasMovedDuringPress = false
  initialTouchTarget = null
}

// Mouse event handlers
function handleMouseDown(event) {
  handlePointerStart(event)
}

function handleMouseMove(event) {
  handlePointerMove(event)
}

function handleMouseUp(event) {
  handlePointerEnd(event)
}

// Touch event handlers
function handleTouchStart(event) {
  handlePointerStart(event)
}

function handleTouchMove(event) {
  handlePointerMove(event)
}

function handleTouchEnd(event) {
  handlePointerEnd(event)
}

// Setup and cleanup event listeners
function setupGestures() {
  if (!containerRef.value) return
  
  const container = containerRef.value
  
  // Mouse events
  container.addEventListener('mousedown', handleMouseDown, { passive: false })
  document.addEventListener('mousemove', handleMouseMove, { passive: false })
  document.addEventListener('mouseup', handleMouseUp, { passive: false })
  
  // Touch events
  container.addEventListener('touchstart', handleTouchStart, { passive: false })
  container.addEventListener('touchmove', handleTouchMove, { passive: false })
  container.addEventListener('touchend', handleTouchEnd, { passive: false })
  container.addEventListener('touchcancel', handleTouchEnd, { passive: false })
}

function destroyGestures() {
  if (!containerRef.value) return
  
  const container = containerRef.value
  
  // Mouse events
  container.removeEventListener('mousedown', handleMouseDown)
  document.removeEventListener('mousemove', handleMouseMove)
  document.removeEventListener('mouseup', handleMouseUp)
  
  // Touch events
  container.removeEventListener('touchstart', handleTouchStart)
  container.removeEventListener('touchmove', handleTouchMove)
  container.removeEventListener('touchend', handleTouchEnd)
  container.removeEventListener('touchcancel', handleTouchEnd)
}

function setCardRef(el, index) {
  cardRefs.value[index] = el
  if (index === props.notes.length - 1) {
    topCardRef.value = el
  }
}

function handleCardRef(el, index) {
  if (index === props.notes.length - 1) {
    topCardRef.value = el
  }
}

function getCardStyle(index) {
  const isTopCard = index === props.notes.length - 1
  const stackIndex = props.notes.length - 1 - index
  
  const style = {
    zIndex: props.notes.length - index,
    opacity: isTopCard ? 1 : (1 - stackIndex * 0.15),
    visibility: index < props.notes.length - 3 ? 'hidden' : 'visible'
  }
  
  if (isTopCard) {
    style.transform = cardTransform.value
  } else {
    style.transform = `translateY(${stackIndex * 8}px) translateX(${stackIndex * 4}px) scale(${1 - stackIndex * 0.03}) rotate(${stackIndex * 2}deg)`
  }
  
  return style
}

function flipCard(index) {
  if (isDragging.value) return
  emit('flip', index)
}

function handleSwipeRight() {
  cardTransform.value = 'translateX(100vw) rotate(30deg)'
  setTimeout(() => {
    emit('swipeRight')
    cardTransform.value = ''
    isDragging.value = false
  }, 300)
}

function handleSwipeLeft() {
  cardTransform.value = 'translateX(-100vw) rotate(-30deg)'
  setTimeout(() => {
    emit('swipeLeft')
    cardTransform.value = ''
    isDragging.value = false
  }, 300)
}

// Method to trigger automatic swipe right (called programmatically)
function triggerAutoSwipeRight() {
  handleSwipeRight()
}

// Method to trigger automatic swipe left (called programmatically)
function triggerAutoSwipeLeft() {
  handleSwipeLeft()
}

// Lifecycle hooks
onMounted(() => {
  nextTick(() => {
    setupGestures()
  })
})

onUnmounted(() => {
  destroyGestures()
})

// Expose methods
defineExpose({
  setupGestures,
  destroyGestures,
  cardRefs,
  triggerAutoSwipeRight,
  triggerAutoSwipeLeft
})
</script>

<style scoped>
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
  -webkit-touch-callout: none;
  -webkit-tap-highlight-color: transparent;
  touch-action: pan-y pinch-zoom; /* Allow vertical scrolling and zoom but handle horizontal gestures ourselves */
}

/* Mobile responsive */
@media (max-width: 768px) {
  .card-container {
    width: 95vw;
    height: 85vh;
    max-width: 600px;
    max-height: 800px;
  }
}

@media (max-width: 480px) {
  .card-container {
    width: 95vw;
    height: 80vh;
    max-width: 400px;
    max-height: 700px;
  }
}
</style>