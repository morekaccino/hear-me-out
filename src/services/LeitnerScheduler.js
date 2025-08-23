export class LeitnerScheduler {
  constructor(repository) {
    this.repository = repository;
  }

  // Get cards due for review from current available octaves only
  getCardsForReview() {
    const data = this.repository.getData();
    const availableOctaves = this.repository.getAvailableOctaves();
    const now = Date.now();
    
    const dueCards = [];
    
    // Only get cards from available octaves
    Object.values(data.boxes).flat().forEach(card => {
      if (availableOctaves.includes(card.octave) && card.nextReview <= now) {
        dueCards.push(card);
      }
    });
    
    // Prioritize box 1 (new cards), then by next review time
    return dueCards.sort((a, b) => {
      if (a.box !== b.box) {
        return a.box - b.box;
      }
      return a.nextReview - b.nextReview;
    });
  }

  // Move card based on success/failure
  processCardResult(cardId, isCorrect) {
    const data = this.repository.getData();
    let card = null;
    let currentBox = null;
    
    // Find the card
    for (const [boxNum, cards] of Object.entries(data.boxes)) {
      const cardIndex = cards.findIndex(c => c.id === cardId);
      if (cardIndex !== -1) {
        card = cards[cardIndex];
        currentBox = parseInt(boxNum);
        cards.splice(cardIndex, 1);
        break;
      }
    }
    
    if (!card) return false;
    
    // Update card stats
    card.attempts += 1;
    if (isCorrect) card.correct += 1;
    card.lastReview = Date.now();
    
    // Move card to appropriate box
    if (isCorrect) {
      // Move to next box or keep in box 5 (mastered)
      const newBox = Math.min(currentBox + 1, 5);
      card.box = newBox;
      card.nextReview = this.calculateNextReview(newBox);
    } else {
      // Move back to box 1
      card.box = 1;
      card.nextReview = Date.now();
    }
    
    data.boxes[card.box].push(card);
    
    // Update global stats
    data.stats.totalAttempts += 1;
    if (isCorrect) data.stats.totalCorrect += 1;
    
    this.repository.saveData(data);
    
    // Check if we can expand octave range
    this.repository.expandOctaveRange();
    
    return true;
  }

  calculateNextReview(box) {
    const now = Date.now();
    const intervals = {
      1: 0,           // Immediate
      2: 1 * 24 * 60 * 60 * 1000,  // 1 day
      3: 3 * 24 * 60 * 60 * 1000,  // 3 days
      4: 7 * 24 * 60 * 60 * 1000,  // 1 week
      5: 30 * 24 * 60 * 60 * 1000  // 1 month (mastered)
    };
    
    return now + (intervals[box] || 0);
  }

  getProgressStats() {
    const data = this.repository.getData();
    const availableOctaves = this.repository.getAvailableOctaves();
    
    const stats = {
      currentOctaves: availableOctaves,
      totalCards: 0,
      masteredCards: 0,
      dueCards: 0,
      accuracy: 0
    };
    
    Object.values(data.boxes).flat().forEach(card => {
      if (availableOctaves.includes(card.octave)) {
        stats.totalCards += 1;
        if (card.box === 5) stats.masteredCards += 1;
        if (card.nextReview <= Date.now()) stats.dueCards += 1;
      }
    });
    
    if (data.stats.totalAttempts > 0) {
      stats.accuracy = (data.stats.totalCorrect / data.stats.totalAttempts) * 100;
    }
    
    return stats;
  }
}
