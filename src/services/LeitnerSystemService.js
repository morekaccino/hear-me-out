import { PLAYABLE_NOTES } from '../config/notes.config'

export class LeitnerSystemService {
  constructor(storageAdapter) {
    this.storage = storageAdapter
    this.data = null
    this.NUM_BOXES = 5
    this.initialize()
  }

  initialize() {
    const savedData = this.storage.load()
    
    if (savedData) {
      this.data = savedData
    } else {
      this.data = {
        cards: PLAYABLE_NOTES.map((noteValue, index) => ({
          noteId: `note_${index}`,
          noteValue,
          box: 1,
          lastReviewedSession: 0,
          stats: {
            totalReviews: 0,
            correctCount: 0,
            incorrectCount: 0
          }
        })),
        sessionCount: 1,
        currentSessionCards: [],
        sessionStats: {
          cardsReviewed: 0,
          correctCount: 0,
          incorrectCount: 0
        }
      }
      
      this._prepareCurrentSession()
      this._saveData()
    }
  }

  _saveData() {
    this.storage.save(this.data)
  }

  _prepareCurrentSession() {
    const cardsToReview = this.data.cards.filter(card => {
      const boxInterval = card.box
      const sessionsSinceLastReview = this.data.sessionCount - card.lastReviewedSession
      return sessionsSinceLastReview >= boxInterval
    })

    this.data.currentSessionCards = this._shuffleArray(cardsToReview.map(c => c.noteId))
    
    this.data.sessionStats = {
      cardsReviewed: 0,
      correctCount: 0,
      incorrectCount: 0,
      totalCards: this.data.currentSessionCards.length
    }
  }

  _shuffleArray(array) {
    const shuffled = [...array]
    for (let i = shuffled.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]]
    }
    return shuffled
  }

  getNextCard() {
    if (this.data.currentSessionCards.length === 0) {
      return null
    }

    const noteId = this.data.currentSessionCards[0]
    const card = this.data.cards.find(c => c.noteId === noteId)
    
    if (!card) {
      this.data.currentSessionCards.shift()
      return this.getNextCard()
    }

    return {
      id: card.noteId,
      value: card.noteValue,
      isFlipped: false,
      box: card.box,
      stats: card.stats
    }
  }

  markCardCorrect(noteId) {
    const card = this.data.cards.find(c => c.noteId === noteId)
    if (!card) return

    card.stats.totalReviews++
    card.stats.correctCount++
    card.lastReviewedSession = this.data.sessionCount

    if (card.box < this.NUM_BOXES) {
      card.box++
    }

    this.data.sessionStats.cardsReviewed++
    this.data.sessionStats.correctCount++

    this.data.currentSessionCards.shift()
    
    this._saveData()
  }

  markCardIncorrect(noteId) {
    const card = this.data.cards.find(c => c.noteId === noteId)
    if (!card) return

    card.stats.totalReviews++
    card.stats.incorrectCount++
    card.lastReviewedSession = this.data.sessionCount
    card.box = 1

    this.data.sessionStats.cardsReviewed++
    this.data.sessionStats.incorrectCount++

    this.data.currentSessionCards.shift()
    
    this._saveData()
  }

  startNewSession() {
    this.data.sessionCount++
    this._prepareCurrentSession()
    this._saveData()
    
    return {
      sessionCount: this.data.sessionCount,
      cardsToReview: this.data.currentSessionCards.length
    }
  }

  getSessionStats() {
    return {
      ...this.data.sessionStats,
      sessionCount: this.data.sessionCount,
      hasCardsRemaining: this.data.currentSessionCards.length > 0
    }
  }

  getBoxDistribution() {
    const distribution = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 }
    this.data.cards.forEach(card => {
      distribution[card.box]++
    })
    return distribution
  }

  resetProgress() {
    this.storage.clear()
    this.initialize()
  }

  getRemainingCardsCount() {
    return this.data.currentSessionCards.length
  }

  getCurrentSessionNumber() {
    return this.data.sessionCount
  }
}

