<template>
  <div class="card-container" ref="containerRef">
    <Card
      v-for="(note, index) in notes"
      :key="note.id"
      :note="note"
      :is-top-card="index === notes.length - 1"
      :card-style="getCardStyle(index)"
      @flip="flipCard(index)"
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

// --- Pointer Events Unified Handlers ---
function handlePointerDown(event) {
  console.log('[PointerDown]', { pointerType: event.pointerType, button: event.button, target: event.target, isTopCard: isTopCard(event) });
  if (event.pointerType === 'mouse' && event.button !== 0) return
  if (!isTopCard(event)) return

  event.target.setPointerCapture?.(event.pointerId)

  const coords = { x: event.clientX, y: event.clientY }
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
  console.log('[PointerDown] State:', { startX, startY, isPointerDown, hasMovedDuringPress, initialTouchTarget });
}

function handlePointerMove(event) {
  if (!isPointerDown) return
  const coords = { x: event.clientX, y: event.clientY }
  const deltaX = coords.x - startX
  const deltaY = coords.y - startY
  console.log('[PointerMove]', { deltaX, deltaY, isPointerDown, isDragging: isDragging.value });

  if (Math.abs(deltaX) > 5 || Math.abs(deltaY) > 5) {
    hasMovedDuringPress = true
  }

  if (Math.abs(deltaX) > 10 && Math.abs(deltaX) > Math.abs(deltaY)) {
    if (!isDragging.value) {
      isDragging.value = true
      console.log('[PointerMove] Drag started');
    }
    const rotation = deltaX / 20
    cardTransform.value = `translateX(${deltaX}px) rotate(${rotation}deg)`
    event.preventDefault()
    console.log('[PointerMove] Transform:', cardTransform.value)
  }
}

function handlePointerUp(event) {
  if (!isPointerDown) return
  const coords = { x: event.clientX, y: event.clientY }
  const deltaX = coords.x - startX
  const deltaY = coords.y - startY
  const deltaTime = Date.now() - startTime
  const distance = Math.sqrt(deltaX * deltaX + deltaY * deltaY)
  isPointerDown = false
  console.log('[PointerUp]', { deltaX, deltaY, deltaTime, distance, isDragging: isDragging.value, hasMovedDuringPress, initialTouchTarget, eventTarget: event.target });

  // Swipe
  if (isDragging.value && Math.abs(deltaX) > 100) {
    console.log('[PointerUp] Swipe', deltaX > 0 ? 'right' : 'left');
    if (deltaX > 0) {
      handleSwipeRight()
    } else {
      handleSwipeLeft()
    }
  }
  // Tap
  else if (!hasMovedDuringPress && distance < 10 && deltaTime < 300 && event.target === initialTouchTarget) {
    console.log('[PointerUp] Tap/Flip');
    cardTransform.value = ''
    isDragging.value = false
    setTimeout(() => {
      const topCardIndex = props.notes.length - 1
      emit('flip', topCardIndex)
    }, 50)
  }
  // Not a swipe, not a tap: always reset
  else {
    console.log('[PointerUp] Reset');
    cardTransform.value = ''
    isDragging.value = false
  }

  // Always reset state
  startX = 0
  startY = 0
  startTime = 0
  hasMovedDuringPress = false
  initialTouchTarget = null
  console.log('[PointerUp] State reset');
}

function handlePointerCancel(event) {
  console.log('[PointerCancel]');
  cardTransform.value = ''
  isDragging.value = false
  isPointerDown = false
  startX = 0
  startY = 0
  startTime = 0
  hasMovedDuringPress = false
  initialTouchTarget = null
}

function setupGestures() {
  if (!containerRef.value) return
  const container = containerRef.value
  container.addEventListener('pointerdown', handlePointerDown, { passive: false })
  container.addEventListener('pointermove', handlePointerMove, { passive: false })
  container.addEventListener('pointerup', handlePointerUp, { passive: false })
  container.addEventListener('pointercancel', handlePointerCancel, { passive: false })
}

function destroyGestures() {
  if (!containerRef.value) return
  const container = containerRef.value
  container.removeEventListener('pointerdown', handlePointerDown)
  container.removeEventListener('pointermove', handlePointerMove)
  container.removeEventListener('pointerup', handlePointerUp)
  container.removeEventListener('pointercancel', handlePointerCancel)
}

function setCardRef(el, index) {
  cardRefs.value[index] = el
  // Only set topCardRef for the top card, and only if el is a DOM element
  if (index === props.notes.length - 1) {
    if (el && el instanceof HTMLElement) {
      topCardRef.value = el
    } else if (el && el.$el) {
      topCardRef.value = el.$el
    } else {
      topCardRef.value = null
    }
    console.log('[setCardRef] topCardRef.value:', topCardRef.value)
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