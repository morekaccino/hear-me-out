# Progressive Learning Algorithm

This document explains how the new conservative learning algorithm works for the musical note flashcard app.

## Overview

The `ProgressiveLearningService` implements a progressive, conservative learning system that introduces new cards only when you've demonstrated mastery of previous cards. The system automatically saves progress to Firestore, allowing users to resume their learning session across devices and browser sessions.

## Key Features

### 1. **Conservative Card Introduction**
- Starts with just **1 card**
- Introduces **only 1 new card at a time**, never a bunch
- New cards are introduced only when previous cards are being learned

### 2. **Learning Stages**

#### Stage 1: Learning
- Cards you're actively learning
- Maximum of 5 cards in learning at once
- Requires multiple correct answers to progress

#### Stage 2: Mastered
- Cards you've mastered (3 correct answers in a row)
- Occasionally shown for review to prevent forgetting
- Can be demoted back to learning if answered incorrectly

### 3. **When New Cards Are Introduced**

The algorithm introduces a new card when:

- **For the first card**: After answering it correctly 2 times in a row
- **For multiple cards**: When either:
  - At least one card is about to be mastered (3 correct in a row), OR
  - All cards have been answered correctly at least once AND at least one has 2+ correct streak

### 4. **Card Selection Priority**

When deciding which card to show next:

1. **30% chance**: Show a review card from mastered cards (if any exist)
2. **Otherwise**: Show a learning card, prioritizing:
   - Cards with lower correct streaks (need more practice)
   - Cards not seen recently

### 5. **Review System**

- Mastered cards are periodically shown for review
- Review frequency based on:
  - Time since last seen
  - Number of times reviewed
- Incorrect answers on reviews demote the card back to learning

## Algorithm Parameters

```javascript
MASTERY_THRESHOLD = 3           // Correct answers needed to master a card
NEW_CARD_AFTER_REVIEWS = 2      // Correct streak needed before introducing new cards
REVIEW_PROBABILITY = 0.3        // 30% chance to show review cards
MAX_LEARNING_CARDS = 5          // Maximum cards in learning stage at once
```

## Example Learning Flow

```
Session Start:
- Card: E2 (new)

User answers E2 correctly:
- E2 streak: 1
- Continue showing E2

User answers E2 correctly again:
- E2 streak: 2
- Introduce new card F2

User answers F2 correctly:
- F2 streak: 1
- E2 streak: 2, F2 streak: 1
- Keep showing current cards

User answers E2 correctly:
- E2 streak: 3 → E2 MASTERED! 🎉
- E2 moved to mastered cards

User answers F2 correctly twice more:
- F2 streak: 3 → F2 MASTERED! 🎉
- Introduce new card F#2

... and so on

Later in session:
- 30% chance to review E2 or F2 (from mastered)
- 70% chance to continue with learning cards
```

## Benefits

1. **Prevents Overwhelm**: Never shows too many new cards at once
2. **Ensures Retention**: Regular reviews prevent forgetting
3. **Adaptive**: Adjusts to your learning pace
4. **Progressive**: Gradually increases difficulty as you master cards
5. **Focused**: Concentrates on cards that need practice

## Integration

The service is used via the `useProgressiveLearning` composable:

```javascript
const { 
  generateInitialStack,  // Creates initial card stack
  getNextCard,           // Gets next card based on algorithm
  markCorrect,           // Records correct answer
  markIncorrect,         // Records incorrect answer
  stats,                 // Learning statistics
  isInitialized,         // Whether user data is loaded
  isSaving               // Whether progress is being saved
} = useProgressiveLearning()
```

## Firestore Integration

### Data Structure

Learning progress is stored in Firestore at:
```
/users/{userId}/learningProgress/current
```

### Saved Data
- **learningCards**: Array of cards currently being learned
  - noteValue, correctStreak, totalCorrect, totalIncorrect, lastSeen
- **masteredCards**: Array of mastered cards
  - All learning card fields plus masteredAt, reviewCount
- **cardIdCounter**: Counter for generating unique card IDs
- **stats**: Overall learning statistics

### Auto-Save
- Progress is automatically saved to Firestore after every correct/incorrect answer
- Debounced with 500ms delay to avoid excessive writes
- Seamless - no manual save required

### User Authentication
- Uses Firebase Anonymous Authentication
- Each user gets a unique ID automatically
- Progress tied to user ID
- Works across devices if same anonymous user

## Notes

- Progress is automatically persisted to Firestore
- Users can close the browser and resume later
- The UI remains unchanged - only the card selection logic is different
- The algorithm prioritizes learning quality over speed
- Firestore rules should be configured to allow authenticated users to read/write their own data

