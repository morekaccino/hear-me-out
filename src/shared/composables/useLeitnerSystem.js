import { ref, computed } from 'vue'
import { LeitnerSystemService } from '../../services/LeitnerSystemService'
import { StorageAdapter } from '../../services/StorageAdapter'

let leitnerInstance = null

export function useLeitnerSystem() {
  if (!leitnerInstance) {
    const storage = new StorageAdapter()
    leitnerInstance = new LeitnerSystemService(storage)
  }

  const currentCard = ref(null)
  const sessionStats = ref(leitnerInstance.getSessionStats())
  const remainingCards = ref(leitnerInstance.getRemainingCardsCount())

  const hasCardsRemaining = computed(() => remainingCards.value > 0)
  const sessionComplete = computed(() => !hasCardsRemaining.value)

  function loadNextCard() {
    const card = leitnerInstance.getNextCard()
    currentCard.value = card
    remainingCards.value = leitnerInstance.getRemainingCardsCount()
    sessionStats.value = leitnerInstance.getSessionStats()
    return card
  }

  function markCorrect() {
    if (!currentCard.value) return
    
    leitnerInstance.markCardCorrect(currentCard.value.id)
    sessionStats.value = leitnerInstance.getSessionStats()
    remainingCards.value = leitnerInstance.getRemainingCardsCount()
  }

  function markIncorrect() {
    if (!currentCard.value) return
    
    leitnerInstance.markCardIncorrect(currentCard.value.id)
    sessionStats.value = leitnerInstance.getSessionStats()
    remainingCards.value = leitnerInstance.getRemainingCardsCount()
  }

  function startNewSession() {
    const result = leitnerInstance.startNewSession()
    sessionStats.value = leitnerInstance.getSessionStats()
    remainingCards.value = leitnerInstance.getRemainingCardsCount()
    return result
  }

  function getBoxDistribution() {
    return leitnerInstance.getBoxDistribution()
  }

  function resetProgress() {
    leitnerInstance.resetProgress()
    sessionStats.value = leitnerInstance.getSessionStats()
    remainingCards.value = leitnerInstance.getRemainingCardsCount()
    currentCard.value = null
  }

  function generateStack(size = 5) {
    const stack = []
    const tempCards = []
    
    for (let i = 0; i < size; i++) {
      const card = leitnerInstance.getNextCard()
      if (card) {
        tempCards.push(card)
        stack.push(card)
      }
    }
    
    tempCards.reverse()
    tempCards.forEach(card => {
      leitnerInstance.data.currentSessionCards.unshift(card.id)
    })
    
    return stack
  }

  return {
    currentCard,
    sessionStats,
    remainingCards,
    hasCardsRemaining,
    sessionComplete,
    loadNextCard,
    markCorrect,
    markIncorrect,
    startNewSession,
    getBoxDistribution,
    resetProgress,
    generateStack
  }
}

