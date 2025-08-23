import { ref, computed } from 'vue';
import { LeitnerRepository } from '../services/LeitnerRepository.js';
import { LeitnerScheduler } from '../services/LeitnerScheduler.js';

export function useLeitnerSystem() {
  const repository = new LeitnerRepository();
  const scheduler = new LeitnerScheduler(repository);
  
  const currentCard = ref(null);
  const isInitialized = ref(false);
  
  // Initialize with octave 4 cards
  const initialize = () => {
    repository.initializeOctaveCards(4);
    isInitialized.value = true;
  };
  
  // Get next card for review
  const getNextCard = () => {
    const dueCards = scheduler.getCardsForReview();
    if (dueCards.length > 0) {
      currentCard.value = dueCards[0];
      return currentCard.value;
    }
    currentCard.value = null;
    return null;
  };
  
  // Process user's answer
  const submitAnswer = (isCorrect) => {
    if (!currentCard.value) return false;
    
    const success = scheduler.processCardResult(currentCard.value.id, isCorrect);
    if (success) {
      // Get next card
      getNextCard();
    }
    return success;
  };
  
  // Get current progress statistics
  const progress = computed(() => scheduler.getProgressStats());
  
  // Check if new octave was unlocked
  const availableOctaves = computed(() => repository.getAvailableOctaves());
  
  // Reset the system
  const reset = () => {
    repository.reset();
    currentCard.value = null;
    isInitialized.value = false;
  };
  
  return {
    currentCard,
    isInitialized,
    progress,
    availableOctaves,
    initialize,
    getNextCard,
    submitAnswer,
    reset
  };
}
