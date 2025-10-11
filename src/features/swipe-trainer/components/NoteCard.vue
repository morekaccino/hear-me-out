<template>
  <div 
    :class="['note-card', { 'top-card': isTopCard, 'flipped': note.isFlipped }]"
    :style="cardStyle"
    :ref="setCardRef"
  >
    <div class="card-content">
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
      
      <div class="card-back">
        <div class="note-letter">{{ note.value }}</div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUpdated, nextTick } from 'vue'
import { shiftNoteOctave } from '../../../shared/utils/noteConversion'

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

  notationLoaded.value = false

  try {
    const { Renderer, Stave, StaveNote, Voice, Formatter, Accidental } = await import('vexflow')

    vexflowRef.value.innerHTML = ''

    const renderer = new Renderer(vexflowRef.value, Renderer.Backends.SVG)
    
    const width = 800
    const height = 600
    const scale = 3.5

    renderer.resize(width, height)
    const context = renderer.getContext()
    context.scale(scale, scale)

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

    vexflowRef.value.setAttribute('data-rendered', 'true')

    setTimeout(() => {
      notationLoaded.value = true
    }, 50)

  } catch (error) {
    console.error('VexFlow rendering error:', error)
  }
}

function noteToVexFlowKey(note) {
  const match = note.match(/^([A-G]#?)(-?\d+)$/)
  if (!match) return note
  const [, base, octStr] = match
  const written = shiftNoteOctave(`${base}${octStr}`, 1)
  const writtenMatch = written.match(/^([A-G]#?)(-?\d+)$/)
  const [, writtenBase, writtenOct] = writtenMatch
  return `${writtenBase.toLowerCase()}/${writtenOct}`
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
    notationLoaded.value = false
    if (vexflowRef.value) {
      vexflowRef.value.innerHTML = ''
      vexflowRef.value.removeAttribute('data-rendered')
    }
  }
})

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
  transition: transform var(--transition-normal), 
              box-shadow var(--transition-normal), 
              opacity var(--transition-normal);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-lg), var(--shadow-md), var(--shadow-sm);
  user-select: none;
  -webkit-user-select: none;
  border: 1px solid var(--border-glass);
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
  box-shadow: var(--shadow-xl), var(--shadow-lg), var(--shadow-md);
}

.card-content {
  position: relative;
  width: 100%;
  height: 100%;
  min-height: 0;
  border-radius: var(--radius-lg);
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
  border-radius: var(--radius-lg);
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--bg-glass);
  backdrop-filter: blur(10px);
  padding: 0;
  margin: 0;
  user-select: none;
  -webkit-user-select: none;
  border: 1px solid var(--border-glass-strong);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.4);
}

.card-back {
  transform: rotateY(180deg);
  background: rgba(255, 255, 255, 0.98);
}

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
  pointer-events: none;
  overflow: hidden;
  position: relative;
  opacity: 0;
  transform: scale(0.8) translateY(20px);
  transition: opacity var(--transition-normal), 
              transform var(--transition-normal);
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
  pointer-events: none;
}

.note-letter {
  font-size: 12rem;
  font-weight: bold;
  color: var(--text-primary);
  text-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
  user-select: none;
  pointer-events: none;
}

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
  pointer-events: none;
}

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

