import { PLAYABLE_NOTES } from '../config/notes.config'

export class ProgressiveLearningService {
  constructor(initialState = null) {
    this.allNotes = [...PLAYABLE_NOTES]
    this.learningCards = []
    this.reviewQueue = []
    this.masteredCards = []
    this.currentCardIndex = 0
    this.cardIdCounter = 0
    
    this.MASTERY_THRESHOLD = 3
    this.NEW_CARD_AFTER_REVIEWS = 2
    this.REVIEW_PROBABILITY = 0.7
    this.MAX_LEARNING_CARDS = 5
    
    if (initialState) {
      this._restoreState(initialState)
    } else {
      this._initializeFirstCards()
    }
  }

  _initializeFirstCards() {
    const firstNote = this.allNotes[0]
    this.learningCards.push({
      noteValue: firstNote,
      correctStreak: 0,
      totalCorrect: 0,
      totalIncorrect: 0,
      lastSeen: Date.now()
    })
  }

  _shouldIntroduceNewCard() {
    if (this.learningCards.length >= this.MAX_LEARNING_CARDS) {
      return false
    }

    if (this.masteredCards.length + this.learningCards.length >= this.allNotes.length) {
      return false
    }

    if (this.learningCards.length === 0) {
      return true
    }

    if (this.learningCards.length === 1) {
      return this.learningCards[0].correctStreak >= this.NEW_CARD_AFTER_REVIEWS
    }

    const hasMasteredCard = this.learningCards.some(card => 
      card.correctStreak >= this.MASTERY_THRESHOLD
    )
    
    if (hasMasteredCard) {
      return true
    }

    const allCardsProgressing = this.learningCards.every(card => 
      card.totalCorrect >= 1
    )
    
    return allCardsProgressing && this.learningCards.some(card => 
      card.correctStreak >= this.NEW_CARD_AFTER_REVIEWS
    )
  }

  _introduceNewCard() {
    const learnedCount = this.masteredCards.length + this.learningCards.length
    
    if (learnedCount >= this.allNotes.length) {
      return null
    }

    const nextNote = this.allNotes[learnedCount]
    const newCard = {
      noteValue: nextNote,
      correctStreak: 0,
      totalCorrect: 0,
      totalIncorrect: 0,
      lastSeen: Date.now()
    }
    
    this.learningCards.push(newCard)
    return newCard
  }

  _promoteToMastered(card) {
    const index = this.learningCards.indexOf(card)
    if (index > -1) {
      this.learningCards.splice(index, 1)
      this.masteredCards.push({
        ...card,
        masteredAt: Date.now(),
        reviewCount: 0
      })
    }
  }

  _demoteToLearning(card) {
    const index = this.masteredCards.indexOf(card)
    if (index > -1) {
      this.masteredCards.splice(index, 1)
      this.learningCards.push({
        noteValue: card.noteValue,
        correctStreak: 0,
        totalCorrect: card.totalCorrect || 0,
        totalIncorrect: (card.totalIncorrect || 0) + 1,
        lastSeen: Date.now()
      })
    }
  }

  _shouldShowReviewCard() {
    if (this.masteredCards.length === 0) {
      return false
    }

    return Math.random() < this.REVIEW_PROBABILITY
  }

  _selectReviewCard() {
    if (this.masteredCards.length === 0) {
      return null
    }

    const sorted = [...this.masteredCards].sort((a, b) => {
      const timeDiff = a.lastSeen - b.lastSeen
      if (Math.abs(timeDiff) > 10000) {
        return timeDiff
      }
      return a.reviewCount - b.reviewCount
    })

    return sorted[0]
  }

  _selectLearningCard() {
    if (this.learningCards.length === 0) {
      return null
    }

    const sorted = [...this.learningCards].sort((a, b) => {
      const streakDiff = a.correctStreak - b.correctStreak
      if (streakDiff !== 0) {
        return streakDiff
      }
      return a.lastSeen - b.lastSeen
    })

    return sorted[0]
  }

  getNextCard() {
    if (this._shouldIntroduceNewCard()) {
      const newCard = this._introduceNewCard()
      if (newCard) {
        return this._createCardObject(newCard, 'new')
      }
    }

    if (this._shouldShowReviewCard()) {
      const reviewCard = this._selectReviewCard()
      if (reviewCard) {
        return this._createCardObject(reviewCard, 'review')
      }
    }

    const learningCard = this._selectLearningCard()
    if (learningCard) {
      return this._createCardObject(learningCard, 'learning')
    }

    if (this.masteredCards.length > 0) {
      const reviewCard = this._selectReviewCard()
      return this._createCardObject(reviewCard, 'review')
    }

    return null
  }

  _createCardObject(card, cardType) {
    return {
      id: `card_${this.cardIdCounter++}`,
      value: card.noteValue,
      isFlipped: false,
      cardType,
      metadata: {
        correctStreak: card.correctStreak || 0,
        totalCorrect: card.totalCorrect || 0,
        totalIncorrect: card.totalIncorrect || 0
      }
    }
  }

  markCorrect(cardValue) {
    let card = this.learningCards.find(c => c.noteValue === cardValue)
    let isReview = false

    if (!card) {
      card = this.masteredCards.find(c => c.noteValue === cardValue)
      isReview = true
    }

    if (!card) {
      return
    }

    card.correctStreak = (card.correctStreak || 0) + 1
    card.totalCorrect = (card.totalCorrect || 0) + 1
    card.lastSeen = Date.now()

    if (isReview) {
      card.reviewCount = (card.reviewCount || 0) + 1
    } else if (card.correctStreak >= this.MASTERY_THRESHOLD) {
      this._promoteToMastered(card)
    }
  }

  markIncorrect(cardValue) {
    let card = this.learningCards.find(c => c.noteValue === cardValue)
    let isReview = false

    if (!card) {
      card = this.masteredCards.find(c => c.noteValue === cardValue)
      isReview = true
    }

    if (!card) {
      return
    }

    card.correctStreak = 0
    card.totalIncorrect = (card.totalIncorrect || 0) + 1
    card.lastSeen = Date.now()

    if (isReview) {
      this._demoteToLearning(card)
    }
  }

  getProgress() {
    return {
      total: this.allNotes.length,
      learning: this.learningCards.length,
      mastered: this.masteredCards.length,
      notStarted: this.allNotes.length - this.learningCards.length - this.masteredCards.length,
      progressPercentage: Math.round(
        ((this.masteredCards.length + this.learningCards.length * 0.5) / this.allNotes.length) * 100
      )
    }
  }

  getStats() {
    const totalCorrect = this.learningCards.reduce((sum, c) => sum + c.totalCorrect, 0) +
                        this.masteredCards.reduce((sum, c) => sum + (c.totalCorrect || 0), 0)
    
    const totalIncorrect = this.learningCards.reduce((sum, c) => sum + c.totalIncorrect, 0) +
                          this.masteredCards.reduce((sum, c) => sum + (c.totalIncorrect || 0), 0)

    return {
      totalCorrect,
      totalIncorrect,
      accuracy: totalCorrect + totalIncorrect > 0 
        ? Math.round((totalCorrect / (totalCorrect + totalIncorrect)) * 100) 
        : 0,
      ...this.getProgress()
    }
  }

  reset() {
    this.learningCards = []
    this.reviewQueue = []
    this.masteredCards = []
    this.currentCardIndex = 0
    this.cardIdCounter = 0
    this._initializeFirstCards()
  }

  serializeState() {
    return {
      learningCards: this.learningCards.map(card => ({
        noteValue: card.noteValue,
        correctStreak: card.correctStreak,
        totalCorrect: card.totalCorrect,
        totalIncorrect: card.totalIncorrect,
        lastSeen: card.lastSeen
      })),
      masteredCards: this.masteredCards.map(card => ({
        noteValue: card.noteValue,
        correctStreak: card.correctStreak || 0,
        totalCorrect: card.totalCorrect || 0,
        totalIncorrect: card.totalIncorrect || 0,
        lastSeen: card.lastSeen,
        masteredAt: card.masteredAt,
        reviewCount: card.reviewCount || 0
      })),
      cardIdCounter: this.cardIdCounter,
      stats: this.getStats()
    }
  }

  _restoreState(state) {
    if (state.learningCards) {
      this.learningCards = state.learningCards.map(card => ({
        noteValue: card.noteValue,
        correctStreak: card.correctStreak || 0,
        totalCorrect: card.totalCorrect || 0,
        totalIncorrect: card.totalIncorrect || 0,
        lastSeen: card.lastSeen || Date.now()
      }))
    }

    if (state.masteredCards) {
      this.masteredCards = state.masteredCards.map(card => ({
        noteValue: card.noteValue,
        correctStreak: card.correctStreak || 0,
        totalCorrect: card.totalCorrect || 0,
        totalIncorrect: card.totalIncorrect || 0,
        lastSeen: card.lastSeen || Date.now(),
        masteredAt: card.masteredAt || Date.now(),
        reviewCount: card.reviewCount || 0
      }))
    }

    this.cardIdCounter = state.cardIdCounter || 0

    if (this.learningCards.length === 0 && this.masteredCards.length === 0) {
      this._initializeFirstCards()
    }
  }
}

