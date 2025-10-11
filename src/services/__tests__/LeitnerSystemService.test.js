import { LeitnerSystemService } from '../LeitnerSystemService'

class MockStorageAdapter {
  constructor() {
    this.data = null
  }

  save(data) {
    this.data = JSON.parse(JSON.stringify(data))
  }

  load() {
    return this.data ? JSON.parse(JSON.stringify(this.data)) : null
  }

  clear() {
    this.data = null
  }
}

function runTests() {
  console.group('🧪 Leitner System Tests')

  const storage = new MockStorageAdapter()
  const leitner = new LeitnerSystemService(storage)

  console.assert(leitner.data !== null, '✅ Test 1: System initializes')
  console.assert(leitner.data.sessionCount === 1, '✅ Test 2: Session count starts at 1')
  console.assert(leitner.data.cards.length > 0, '✅ Test 3: Cards are initialized')
  console.assert(
    leitner.data.currentSessionCards.length === leitner.data.cards.length,
    '✅ Test 4: All cards in Box 1 on first session'
  )

  const firstCard = leitner.getNextCard()
  console.assert(firstCard !== null, '✅ Test 5: Can get next card')
  console.assert(firstCard.box === 1, '✅ Test 6: First card is in Box 1')

  leitner.markCardCorrect(firstCard.id)
  const updatedCard = leitner.data.cards.find(c => c.noteId === firstCard.id)
  console.assert(updatedCard.box === 2, '✅ Test 7: Correct answer promotes to Box 2')
  console.assert(updatedCard.stats.correctCount === 1, '✅ Test 8: Stats updated correctly')

  const secondCard = leitner.getNextCard()
  leitner.markIncorrect(secondCard.id)
  const incorrectCard = leitner.data.cards.find(c => c.noteId === secondCard.id)
  console.assert(incorrectCard.box === 1, '✅ Test 9: Incorrect answer demotes to Box 1')
  console.assert(incorrectCard.stats.incorrectCount === 1, '✅ Test 10: Incorrect stats updated')

  for (let i = 0; i < 5; i++) {
    const card = leitner.getNextCard()
    if (card) {
      leitner.markCardCorrect(card.id)
    }
  }

  const distribution = leitner.getBoxDistribution()
  console.assert(
    Object.values(distribution).reduce((a, b) => a + b, 0) === leitner.data.cards.length,
    '✅ Test 11: Box distribution accounts for all cards'
  )

  const initialSession = leitner.data.sessionCount
  leitner.startNewSession()
  console.assert(
    leitner.data.sessionCount === initialSession + 1,
    '✅ Test 12: Session count increments'
  )

  storage.clear()
  const newLeitner = new LeitnerSystemService(storage)
  console.assert(
    newLeitner.data.cards.length > 0,
    '✅ Test 13: System reinitializes after clear'
  )

  console.groupEnd()
  console.log('🎉 All tests passed!')
}

if (typeof window !== 'undefined') {
  window.runLeitnerTests = runTests
  console.log('🧪 Leitner tests available at: window.runLeitnerTests()')
}

export { runTests }

