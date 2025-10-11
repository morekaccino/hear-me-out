import { StorageAdapter } from './StorageAdapter'

export class LeitnerDebugger {
  constructor() {
    this.storage = new StorageAdapter()
  }

  printCurrentState() {
    const data = this.storage.load()
    if (!data) {
      console.log('No Leitner data found')
      return
    }

    console.group('📊 Leitner System State')
    console.log(`Session: ${data.sessionCount}`)
    console.log(`Cards Remaining: ${data.currentSessionCards.length}`)
    console.log(`Session Stats:`, data.sessionStats)
    console.groupEnd()

    this.printBoxDistribution()
  }

  printBoxDistribution() {
    const data = this.storage.load()
    if (!data) return

    const distribution = { 1: [], 2: [], 3: [], 4: [], 5: [] }
    
    data.cards.forEach(card => {
      distribution[card.box].push(card.noteValue)
    })

    console.group('📦 Box Distribution')
    for (let box = 1; box <= 5; box++) {
      const cards = distribution[box]
      console.log(`Box ${box} (${cards.length} cards):`, cards.join(', '))
    }
    console.groupEnd()
  }

  printCardStats(noteValue) {
    const data = this.storage.load()
    if (!data) return

    const card = data.cards.find(c => c.noteValue === noteValue)
    if (!card) {
      console.log(`Card not found: ${noteValue}`)
      return
    }

    console.group(`🎵 Stats for ${noteValue}`)
    console.log(`Box: ${card.box}`)
    console.log(`Last Reviewed: Session ${card.lastReviewedSession}`)
    console.log(`Total Reviews: ${card.stats.totalReviews}`)
    console.log(`Correct: ${card.stats.correctCount}`)
    console.log(`Incorrect: ${card.stats.incorrectCount}`)
    console.log(`Accuracy: ${card.stats.totalReviews > 0 ? 
      ((card.stats.correctCount / card.stats.totalReviews) * 100).toFixed(1) : 0}%`)
    console.groupEnd()
  }

  simulateCorrectAnswers(count = 5) {
    const data = this.storage.load()
    if (!data) return

    console.log(`Simulating ${count} correct answers...`)
    
    for (let i = 0; i < count && data.currentSessionCards.length > 0; i++) {
      const noteId = data.currentSessionCards[0]
      const card = data.cards.find(c => c.noteId === noteId)
      
      if (card) {
        card.stats.totalReviews++
        card.stats.correctCount++
        card.lastReviewedSession = data.sessionCount
        
        if (card.box < 5) {
          card.box++
        }
        
        data.sessionStats.cardsReviewed++
        data.sessionStats.correctCount++
        data.currentSessionCards.shift()
        
        console.log(`✅ ${card.noteValue}: Box ${card.box - 1} → Box ${card.box}`)
      }
    }

    this.storage.save(data)
    console.log('Simulation complete!')
    this.printCurrentState()
  }

  simulateIncorrectAnswers(count = 3) {
    const data = this.storage.load()
    if (!data) return

    console.log(`Simulating ${count} incorrect answers...`)
    
    for (let i = 0; i < count && data.currentSessionCards.length > 0; i++) {
      const noteId = data.currentSessionCards[0]
      const card = data.cards.find(c => c.noteId === noteId)
      
      if (card) {
        const oldBox = card.box
        card.stats.totalReviews++
        card.stats.incorrectCount++
        card.lastReviewedSession = data.sessionCount
        card.box = 1
        
        data.sessionStats.cardsReviewed++
        data.sessionStats.incorrectCount++
        data.currentSessionCards.shift()
        
        console.log(`❌ ${card.noteValue}: Box ${oldBox} → Box 1`)
      }
    }

    this.storage.save(data)
    console.log('Simulation complete!')
    this.printCurrentState()
  }

  fastForwardToNextSession() {
    const data = this.storage.load()
    if (!data) return

    const prevSession = data.sessionCount
    data.sessionCount++
    
    const cardsToReview = data.cards.filter(card => {
      const boxInterval = card.box
      const sessionsSinceLastReview = data.sessionCount - card.lastReviewedSession
      return sessionsSinceLastReview >= boxInterval
    })

    data.currentSessionCards = cardsToReview.map(c => c.noteId)
    data.sessionStats = {
      cardsReviewed: 0,
      correctCount: 0,
      incorrectCount: 0,
      totalCards: data.currentSessionCards.length
    }

    this.storage.save(data)
    console.log(`Fast forwarded: Session ${prevSession} → Session ${data.sessionCount}`)
    console.log(`Cards to review: ${data.currentSessionCards.length}`)
    this.printBoxDistribution()
  }

  reset() {
    this.storage.clear()
    console.log('🔄 Leitner system reset. Refresh the page to reinitialize.')
  }

  exportData() {
    const data = this.storage.load()
    if (!data) {
      console.log('No data to export')
      return
    }
    
    const json = JSON.stringify(data, null, 2)
    console.log('📤 Export Data:')
    console.log(json)
    return data
  }

  importData(data) {
    try {
      this.storage.save(data)
      console.log('✅ Data imported successfully. Refresh the page.')
    } catch (error) {
      console.error('❌ Import failed:', error)
    }
  }
}

if (typeof window !== 'undefined') {
  window.LeitnerDebugger = new LeitnerDebugger()
  console.log('🔍 Leitner Debugger available at: window.LeitnerDebugger')
  console.log('Try: LeitnerDebugger.printCurrentState()')
}

export default LeitnerDebugger

