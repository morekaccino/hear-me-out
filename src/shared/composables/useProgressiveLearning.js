import { ref, computed, watch } from 'vue'
import { ProgressiveLearningService } from '../../services/ProgressiveLearningService'
import { learningProgressService } from '../services/firestore'
import { useAuth } from './useAuth'

let serviceInstance = null
let currentUserId = null
let saveTimeout = null

export function useProgressiveLearning() {
  const { user, initAuth } = useAuth()
  const isInitialized = ref(false)
  const isSaving = ref(false)

  const stats = ref({
    totalCorrect: 0,
    totalIncorrect: 0,
    accuracy: 0,
    total: 0,
    learning: 0,
    mastered: 0,
    notStarted: 0,
    progressPercentage: 0
  })

  const progressPercentage = computed(() => stats.value.progressPercentage)
  const totalCards = computed(() => stats.value.total)
  const masteredCount = computed(() => stats.value.mastered)
  const learningCount = computed(() => stats.value.learning)

  async function _initialize() {
    if (isInitialized.value) return

    await initAuth()
    
    if (user.value?.uid) {
      currentUserId = user.value.uid
      await _loadProgress()
      isInitialized.value = true
    }
  }

  async function _loadProgress() {
    if (!currentUserId) return

    const savedProgress = await learningProgressService.loadProgress(currentUserId)
    
    if (savedProgress && savedProgress.learningCards) {
      serviceInstance = new ProgressiveLearningService(savedProgress)
    } else {
      serviceInstance = new ProgressiveLearningService()
    }
    
    _updateStats()
  }

  async function _saveProgress() {
    if (!currentUserId || !serviceInstance) return

    if (saveTimeout) {
      clearTimeout(saveTimeout)
    }

    saveTimeout = setTimeout(async () => {
      isSaving.value = true
      const state = serviceInstance.serializeState()
      await learningProgressService.saveProgress(currentUserId, state)
      isSaving.value = false
    }, 500)
  }

  function _ensureInitialized() {
    if (!serviceInstance) {
      serviceInstance = new ProgressiveLearningService()
    }
  }

  async function getNextCard() {
    await _initialize()
    _ensureInitialized()
    
    const card = serviceInstance.getNextCard()
    _updateStats()
    return card
  }

  async function markCorrect(cardValue) {
    await _initialize()
    _ensureInitialized()
    
    serviceInstance.markCorrect(cardValue)
    _updateStats()
    await _saveProgress()
  }

  async function markIncorrect(cardValue) {
    await _initialize()
    _ensureInitialized()
    
    serviceInstance.markIncorrect(cardValue)
    _updateStats()
    await _saveProgress()
  }

  async function reset() {
    await _initialize()
    _ensureInitialized()
    
    serviceInstance.reset()
    _updateStats()
    
    if (currentUserId) {
      await learningProgressService.resetProgress(currentUserId)
    }
  }

  function _updateStats() {
    if (serviceInstance) {
      stats.value = serviceInstance.getStats()
    }
  }

  async function generateInitialStack(size = 5) {
    await _initialize()
    _ensureInitialized()
    
    const stack = []
    for (let i = 0; i < size; i++) {
      const card = serviceInstance.getNextCard()
      if (card) {
        stack.push(card)
      } else {
        break
      }
    }
    _updateStats()
    return stack
  }

  watch(user, async (newUser) => {
    if (newUser?.uid && newUser.uid !== currentUserId) {
      currentUserId = newUser.uid
      await _loadProgress()
    }
  })

  return {
    stats,
    progressPercentage,
    totalCards,
    masteredCount,
    learningCount,
    isInitialized,
    isSaving,
    getNextCard,
    markCorrect,
    markIncorrect,
    reset,
    generateInitialStack
  }
}

