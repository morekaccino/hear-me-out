<template>
  <div class="leitner-trainer">
    <div class="progress-header">
      <h2>Leitner Music Trainer</h2>
      <div class="stats">
        <span>Octaves: {{ availableOctaves.join('-') }}</span>
        <span>Due: {{ progress.dueCards }}</span>
        <span>Mastered: {{ progress.masteredCards }}/{{ progress.totalCards }}</span>
        <span>Accuracy: {{ progress.accuracy.toFixed(1) }}%</span>
      </div>
    </div>

    <div v-if="!isInitialized" class="setup">
      <button @click="initialize" class="start-btn">
        Start Learning (Octave 4)
      </button>
    </div>

    <div v-else-if="!currentCard" class="no-cards">
      <h3>No cards due for review!</h3>
      <p>Check back later or practice more to unlock new octaves.</p>
      <button @click="getNextCard" class="refresh-btn">Check Again</button>
    </div>

    <div v-else class="card-review">
      <div class="note-display">
        <div class="note-symbol">{{ currentCard.note }}</div>
        <div class="octave-info">Octave {{ currentCard.octave }}</div>
      </div>
      
      <div class="card-info">
        <span>Box {{ currentCard.box }}</span>
        <span>Attempts: {{ currentCard.attempts }}</span>
        <span v-if="currentCard.attempts > 0">
          Success: {{ ((currentCard.correct / currentCard.attempts) * 100).toFixed(1) }}%
        </span>
      </div>

      <div class="answer-buttons">
        <button @click="submitAnswer(false)" class="wrong-btn">
          Wrong ❌
        </button>
        <button @click="submitAnswer(true)" class="correct-btn">
          Correct ✅
        </button>
      </div>
    </div>

    <div class="controls">
      <button @click="reset" class="reset-btn">Reset Progress</button>
    </div>
  </div>
</template>

<script>
import { useLeitnerSystem } from '../composables/useLeitnerSystem.js';

export default {
  name: 'LeitnerMusicTrainer',
  setup() {
    const {
      currentCard,
      isInitialized,
      progress,
      availableOctaves,
      initialize,
      getNextCard,
      submitAnswer,
      reset
    } = useLeitnerSystem();

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
};
</script>

<style scoped>
.leitner-trainer {
  max-width: 600px;
  margin: 0 auto;
  padding: 20px;
  font-family: Arial, sans-serif;
}

.progress-header {
  text-align: center;
  margin-bottom: 30px;
}

.stats {
  display: flex;
  justify-content: center;
  gap: 20px;
  margin-top: 10px;
  font-size: 14px;
  color: #666;
}

.setup, .no-cards {
  text-align: center;
  padding: 40px;
}

.start-btn, .refresh-btn {
  padding: 15px 30px;
  font-size: 18px;
  background: #4CAF50;
  color: white;
  border: none;
  border-radius: 8px;
  cursor: pointer;
}

.card-review {
  text-align: center;
  padding: 20px;
  border: 2px solid #ddd;
  border-radius: 12px;
  margin-bottom: 20px;
}

.note-display {
  margin-bottom: 20px;
}

.note-symbol {
  font-size: 72px;
  font-weight: bold;
  color: #333;
  margin-bottom: 10px;
}

.octave-info {
  font-size: 18px;
  color: #666;
}

.card-info {
  display: flex;
  justify-content: center;
  gap: 20px;
  margin-bottom: 30px;
  font-size: 14px;
  color: #888;
}

.answer-buttons {
  display: flex;
  gap: 20px;
  justify-content: center;
}

.wrong-btn, .correct-btn {
  padding: 15px 30px;
  font-size: 18px;
  border: none;
  border-radius: 8px;
  cursor: pointer;
}

.wrong-btn {
  background: #f44336;
  color: white;
}

.correct-btn {
  background: #4CAF50;
  color: white;
}

.controls {
  text-align: center;
  margin-top: 30px;
}

.reset-btn {
  padding: 10px 20px;
  background: #ff9800;
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
}

button:hover {
  opacity: 0.9;
}
</style>
