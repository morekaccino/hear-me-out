<template>
  <div 
    :class="['note-card', { 'top-card': isTopCard, 'flipped': note.isFlipped }]"
    :style="cardStyle"
    :ref="setCardRef"
  >
    <div class="card-content">
      <!-- Front: Staff notation -->
      <div class="card-front">
        <div 
          v-if="isTopCard" 
          ref="vexflowRef" 
          :data-note="note.value" 
          class="vexflow-staff"
          :class="{ 'notation-loaded': notationLoaded }"
        ></div>
        <div v-else class="card-placeholder">♪</div>
      </div>
      
      <!-- Back: Letter -->
      <div class="card-back">
        <div class="note-letter">{{ note.value }}</div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUpdated, nextTick } from 'vue'
import { shiftNoteOctave } from '../utils/pitchDetection.js'

const props = defineProps({
  note: {
    type: Object,
    required: true
  },
  isTopCard: {
    type: Boolean,
    default: false
  },
  cardStyle: {
    type: Object,
    default: () => ({})
  },
  transform: {
    type: String,
    default: ''
  }
})

const emit = defineEmits(['flip', 'cardRef'])

const vexflowRef = ref(null)
const cardRef = ref(null)
const notationLoaded = ref(false)

const setCardRef = (el) => {
  cardRef.value = el
  // Always emit the root DOM element, not the component instance
  if (el && el instanceof HTMLElement) {
    emit('cardRef', el)
  } else if (el && el.$el) {
    emit('cardRef', el.$el)
  } else {
    emit('cardRef', el)
  }
}

async function renderNotation() {
  if (!vexflowRef.value || !props.note.value || !props.isTopCard) return

  // Reset animation state
  notationLoaded.value = false

  try {
    const { Renderer, Stave, StaveNote, Voice, Formatter, Accidental } = await import('vexflow')

    // Clear previous content
    vexflowRef.value.innerHTML = ''

    const renderer = new Renderer(vexflowRef.value, Renderer.Backends.SVG)
    
    // Use fixed large dimensions and a massive scale
    const width = 800
    const height = 600
    const scale = 3.5

    renderer.resize(width, height)
    const context = renderer.getContext()
    context.scale(scale, scale)

    // Center the stave in the new, larger coordinate system
    const staveWidth = 150
    const staveX = (width / scale - staveWidth) / 2
    const staveY = (height / scale - 100) / 2
    
    const stave = new Stave(staveX, staveY, staveWidth)
    stave.addClef('treble')
    stave.setContext(context).draw()

    const vexNote = noteToVexFlowKey(props.note.value)
    const note = new StaveNote({
      clef: 'treble',
      keys: [vexNote],
      duration: 'w'
    })

    if (props.note.value.includes('#')) {
      note.addModifier(new Accidental('#'), 0)
    } else if (props.note.value.includes('b')) {
      note.addModifier(new Accidental('b'), 0)
    }

    const voice = new Voice({ num_beats: 1, beat_value: 4 })
    voice.setStrict(false)
    voice.addTickables([note])

    new Formatter().joinVoices([voice]).format([voice], staveWidth)
    voice.draw(context, stave)

    // Mark as rendered
    vexflowRef.value.setAttribute('data-rendered', 'true')

    // Trigger animation after a small delay to ensure DOM is updated
    setTimeout(() => {
      notationLoaded.value = true
    }, 50)

  } catch (error) {
    console.error('VexFlow rendering error:', error)
  }
}

function noteToVexFlowKey(note) {
  // Use regex to safely parse note name and octave (handles multi-digit octaves like 10)
  const m = note.match(/^([A-G]#?)(-?\d+)$/)
  if (!m) return note
  const [, base, octStr] = m
  // Convert sounding pitch to written (written = sounding + 1)
  const written = shiftNoteOctave(`${base}${octStr}`, 1)
  const wm = written.match(/^([A-G]#?)(-?\d+)$/)
  const [, wbase, woct] = wm
  return `${wbase.toLowerCase()}/${woct}`
}

onMounted(() => {
  if (props.isTopCard) {
    nextTick(() => {
      renderNotation()
    })
  }
})

onUpdated(() => {
  if (props.isTopCard) {
    const isRendered = vexflowRef.value?.getAttribute('data-rendered')
    if (!isRendered) {
      nextTick(() => {
        renderNotation()
      })
    }
  } else {
    // Clear notation for non-top cards to prevent scrambling
    notationLoaded.value = false
    if (vexflowRef.value) {
      vexflowRef.value.innerHTML = ''
      vexflowRef.value.removeAttribute('data-rendered')
    }
  }
})

// Expose renderNotation method
defineExpose({
  renderNotation,
  vexflowRef
})
</script>

<style scoped>

.note-card {
  position: absolute;
  width: 100%;
  height: 100%;
  min-height: 0;
  max-height: 100vh;
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
  transform-style: preserve-3d;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}

.note-card.flipped {
  transform: rotateY(180deg);
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
  min-height: 0;
  border-radius: 20px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
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

/* When the entire card is flipped, adjust the back transform */
.note-card.flipped .card-back {
  transform: rotateY(0deg);
}

.note-card.flipped .card-front {
  transform: rotateY(-180deg);
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
  opacity: 0;
  transform: scale(0.8) translateY(20px);
  transition: opacity 0.3s ease-out, transform 0.3s ease-out;
}

.vexflow-staff.notation-loaded {
  opacity: 1;
  transform: scale(1) translateY(0);
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

/* Counter-rotate the text when card is flipped to keep it readable */
.note-card.flipped .note-letter {
  transform: scaleX(-1);
}

.card-placeholder {
  font-size: 8rem;
  color: rgba(102, 126, 234, 0.3);
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 100%;
  user-select: none;
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  pointer-events: none;
}

/* Mobile responsive */
@media (max-width: 768px) {
  .note-card {
    height: 80vh;
    max-height: 90vh;
  }
  .note-letter {
    font-size: 8rem;
  }
}

@media (max-width: 480px) {
  .note-card {
    height: 70vh;
    max-height: 80vh;
  }
  .note-letter {
    font-size: 6rem;
  }
}
</style>