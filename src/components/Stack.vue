<template>
  <div class="card-container">
    <Card
      v-for="(note, index) in notes" 
      :key="note.id"
      :note="note"
      :is-top-card="index === notes.length - 1"
      :card-style="getCardStyle(index)"
      @flip="flipCard(index)"
      @swipe-start="handleSwipeStart"
      @swipe-move="handleSwipeMove"
      @swipe-end="handleSwipeEnd"
      @card-ref="handleCardRef($event, index)"
      :ref="el => setCardRef(el, index)"
    />
  </div>
</template>

<script setup>
import { ref, computed, nextTick } from 'vue'
import Card from './Card.vue'
import Hammer from 'hammerjs'

const props = defineProps({
  notes: {
    type: Array,
    required: true
  }
})

const emit = defineEmits(['flip', 'swipeRight', 'swipeLeft'])

const cardTransform = ref('')
const isDragging = ref(false)
const cardRefs = ref([])
const topCardRef = ref(null)
let hammerInstance = null

function setCardRef(el, index) {
  cardRefs.value[index] = el
  if (index === props.notes.length - 1) {
    topCardRef.value = el
    nextTick(() => {
      setupGestures()
    })
  }
}

function handleCardRef(el, index) {
  if (index === props.notes.length - 1) {
    topCardRef.value = el
    nextTick(() => {
      setupGestures()
    })
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

function setupGestures() {
  destroyGestures()
  
  if (topCardRef.value && !hammerInstance) {
    hammerInstance = new Hammer(topCardRef.value)
    
    // Enable swipe gestures
    hammerInstance.get('swipe').set({ direction: Hammer.DIRECTION_HORIZONTAL })
    hammerInstance.get('pan').set({ direction: Hammer.DIRECTION_HORIZONTAL })
    
    // Handle pan (drag) events
    hammerInstance.on('panstart', (e) => {
      isDragging.value = true
      // Reset any flip state when starting a swipe
      const topCard = props.notes[props.notes.length - 1]
      if (topCard && topCard.isFlipped) {
        topCard.isFlipped = false
      }
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
          handleSwipeRight()
        } else {
          handleSwipeLeft()
        }
      } else {
        // Reset position
        cardTransform.value = ''
        // Reset dragging state immediately for small movements
        if (Math.abs(deltaX) < 50) {
          isDragging.value = false
        } else {
          setTimeout(() => {
            isDragging.value = false
          }, 100)
        }
      }
    })
    
    // Handle swipe events as backup
    hammerInstance.on('swiperight', () => {
      if (!isDragging.value) {
        handleSwipeRight()
      }
    })
    
    hammerInstance.on('swipeleft', () => {
      if (!isDragging.value) {
        handleSwipeLeft()
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

function handleSwipeStart({ startX, event }) {
  // Reset any flip state when starting a swipe
  const topCard = props.notes[props.notes.length - 1]
  if (topCard && topCard.isFlipped) {
    topCard.isFlipped = false
  }
}

function handleSwipeMove({ deltaX, currentX, event }) {
  cardTransform.value = `translateX(${deltaX}px) rotate(${deltaX / 20}deg)`
}

function handleSwipeEnd({ deltaX, finalX, isDragging: wasDragging, event }) {
  const swipeThreshold = 100

  if (wasDragging && Math.abs(deltaX) > swipeThreshold) {
    if (deltaX > 0) {
      handleSwipeRight()
    } else {
      handleSwipeLeft()
    }
  } else {
    cardTransform.value = ''
    // Reset dragging state immediately for small movements
    if (Math.abs(deltaX) < 50) {
      isDragging.value = false
    } else {
      setTimeout(() => {
        isDragging.value = false
      }, 100)
    }
  }
}

function handleSwipeRight() {
  cardTransform.value = 'translateX(100vw) rotate(30deg)'
  setTimeout(() => {
    emit('swipeRight')
    cardTransform.value = ''
  }, 300)
}

function handleSwipeLeft() {
  cardTransform.value = 'translateX(-100vw) rotate(-30deg)'
  setTimeout(() => {
    emit('swipeLeft')
    cardTransform.value = ''
  }, 300)
}

// Expose methods
defineExpose({
  setupGestures,
  destroyGestures,
  cardRefs
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