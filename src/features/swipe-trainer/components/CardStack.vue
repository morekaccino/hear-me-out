<template>
  <div>
    <div class="card-container" ref="containerRef">
      <NoteCard
        v-for="(note, index) in notes"
        :key="note.id"
        :note="note"
        :is-top-card="index === notes.length - 1"
        :card-style="getCardStyle(index)"
        @flip="flipCard(index)"
        :ref="el => setCardRef(el, index)"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, nextTick, onMounted, onUnmounted, watch } from 'vue'
import NoteCard from './NoteCard.vue'

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
const cardDelta = ref(0)

let startX = 0
let startY = 0
let startTime = 0
let isPointerDown = false
let hasMovedDuringPress = false
let initialTouchTarget = null

watch(() => props.notes, () => {
  topCardRef.value = null
  cardRefs.value = []
  nextTick(() => {
    updateTopCardRef()
  })
}, { deep: true })

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
  }
  return {
    x: event.clientX,
    y: event.clientY
  }
}

function isTopCard(event) {
  return topCardRef.value && topCardRef.value.contains(event.target)
}

function handlePointerDown(event) {
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
}

function handlePointerMove(event) {
  if (!isPointerDown) return
  
  const coords = { x: event.clientX, y: event.clientY }
  const deltaX = coords.x - startX
  const deltaY = coords.y - startY

  if (Math.abs(deltaX) > 5 || Math.abs(deltaY) > 5) {
    hasMovedDuringPress = true
  }

  if (Math.abs(deltaX) > 10 && Math.abs(deltaX) > Math.abs(deltaY)) {
    if (!isDragging.value) {
      isDragging.value = true
    }
    const rotation = deltaX / 20
    cardTransform.value = `translateX(${deltaX}px) rotate(${rotation}deg)`
    cardDelta.value = deltaX
    event.preventDefault()
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

  if (isDragging.value && Math.abs(deltaX) > 100) {
    const topCard = props.notes[props.notes.length - 1]
    if (topCard && topCard.isFlipped) {
      topCard.isFlipped = false
    }
    if (deltaX > 0) {
      handleSwipeRight()
    } else {
      handleSwipeLeft()
    }
  } else if (!hasMovedDuringPress && distance < 10 && deltaTime < 300 && event.target === initialTouchTarget) {
    cardTransform.value = ''
    isDragging.value = false
    setTimeout(() => {
      emit('flip', props.notes.length - 1)
    }, 50)
  } else {
    cardTransform.value = ''
    isDragging.value = false
    cardDelta.value = 0
  }

  startX = 0
  startY = 0
  startTime = 0
  hasMovedDuringPress = false
  initialTouchTarget = null
}

function handlePointerCancel() {
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
  updateTopCardRef()
}

function updateTopCardRef() {
  const lastIndex = props.notes.length - 1
  let candidate = cardRefs.value[lastIndex]
  
  if (!candidate) {
    for (let i = cardRefs.value.length - 1; i >= 0; i--) {
      if (cardRefs.value[i]) {
        candidate = cardRefs.value[i]
        break
      }
    }
  }

  if (!candidate) {
    topCardRef.value = null
    return
  }

  if (candidate instanceof HTMLElement) {
    topCardRef.value = candidate
  } else if (candidate.$el) {
    topCardRef.value = candidate.$el
  } else {
    topCardRef.value = null
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
    
    const max = 400
    const value = Math.max(-max, Math.min(max, cardDelta.value))
    const tint = Math.min(1, Math.abs(value) / max)
    
    if (value > 0) {
      style.background = `linear-gradient(rgba(76,175,80,${tint * 0.28}), rgba(76,175,80,${tint * 0.28})), var(--bg-glass)`
    } else if (value < 0) {
      style.background = `linear-gradient(rgba(244,67,54,${tint * 0.28}), rgba(244,67,54,${tint * 0.28})), var(--bg-glass)`
    } else {
      style.background = 'var(--bg-glass)'
    }
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
    cardDelta.value = 0
  }, 300)
}

function handleSwipeLeft() {
  cardTransform.value = 'translateX(-100vw) rotate(-30deg)'
  setTimeout(() => {
    emit('swipeLeft')
    cardTransform.value = ''
    isDragging.value = false
    cardDelta.value = 0
  }, 300)
}

function triggerAutoSwipeRight() {
  handleSwipeRight()
}

onMounted(() => {
  nextTick(() => {
    setupGestures()
  })
})

onUnmounted(() => {
  destroyGestures()
})

defineExpose({
  setupGestures,
  destroyGestures,
  cardRefs,
  triggerAutoSwipeRight
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
  -webkit-touch-callout: none;
  -webkit-tap-highlight-color: transparent;
  touch-action: pan-y pinch-zoom;
}

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

