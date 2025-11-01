# GitHub Copilot Instructions - Music Note Flashcard Trainer

## Architecture Overview

This is a **Vue 3 + Vite** progressive web app for learning musical notes through real-time pitch detection. The architecture follows a **feature-based structure** with clear separation between business logic (services), UI (components), and reusable utilities (composables).

### Core Technologies
- **Vue 3** (Composition API with `<script setup>`)
- **Firebase** (Anonymous Auth + Firestore for persistence)
- **Pitchy.js** (McLeod Pitch Method for audio detection)
- **VexFlow 5.x** (Professional music staff notation)
- **Vite 7.x** (Build tool - requires Node.js 20.19+ or 22.12+)

### Key Architectural Decisions

1. **Service Layer Pattern**: Business logic lives in stateful service classes (`/src/services/`), NOT in components
   - `ProgressiveLearningService.js` - Progressive learning algorithm (mastery-based card introduction)
   - `LeitnerSystemService.js` - Alternative spaced repetition system (currently unused)
   - Services have `serializeState()`/`_restoreState()` for Firestore persistence

2. **Composables as Bridges**: Vue composables (`/src/shared/composables/`) orchestrate services + Firebase + Vue reactivity
   - `useProgressiveLearning.js` - Manages `ProgressiveLearningService` + auto-saves to Firestore (500ms debounce)
   - `usePitchDetection.js` - Wraps `PitchDetectionService` with Vue refs
   - `useAuth.js` - Firebase Anonymous Auth initialization

3. **Firestore Service Inheritance**: All Firebase operations extend `FirestoreService` base class
   - Example: `LearningProgressService` extends `FirestoreService('learningProgress')`
   - Path structure: `/users/{userId}/{collection}/{docId}`
   - Auto-adds `updated_at` timestamp to all writes

## Development Workflows

### Running the App
```bash
npm run dev  # Starts Vite dev server on http://localhost:5173
```

### Firebase Deployment
```bash
firebase deploy --only firestore:rules  # Deploy security rules
firebase deploy  # Full deployment (requires Node.js upgrade)
```

### Debugging Learning Algorithm
Access `LeitnerDebugger` in browser console (dev mode only):
```javascript
LeitnerDebugger.printCurrentState()
LeitnerDebugger.printBoxDistribution()
LeitnerDebugger.simulateCorrectAnswers(5)
```

## Critical Patterns & Conventions

### 1. Progressive Learning Algorithm (`ProgressiveLearningService`)
**Conservative card introduction** - only 1 new card at a time:
- Starts with first note from `PLAYABLE_NOTES` config
- Introduces new card when: `correctStreak >= NEW_CARD_AFTER_REVIEWS` (default: 2)
- Promotes to "mastered" after 3 correct in a row (`MASTERY_THRESHOLD`)
- Reviews mastered cards with 70% probability (`REVIEW_PROBABILITY`)
- Max 5 cards in learning simultaneously (`MAX_LEARNING_CARDS`)

### 2. Auto-Save Pattern (Firestore Persistence)
All state changes auto-save with **500ms debounce**:
```javascript
// In useProgressiveLearning composable:
async function _saveProgress() {
  if (saveTimeout) clearTimeout(saveTimeout)
  saveTimeout = setTimeout(async () => {
    const state = serviceInstance.serializeState()
    await learningProgressService.saveProgress(currentUserId, state)
  }, 500)
}
```

### 3. Pitch Detection Anti-Bounce
Complex detection system prevents false positives:
- **History-based confidence**: Requires `CONFIDENCE_THRESHOLD` (3) detections in `HISTORY_WINDOW_MS` (400ms)
- **Refractory period**: `REFRACTORY_MS` (2000ms) after valid detection
- **Silence detection**: Requires `SILENCE_FRAMES_TO_REARM` (10) to reset
- See `usePitchDetection.js` for full state machine

### 4. Firestore Service Pattern
When creating new Firebase collections:
```javascript
// Step 1: Create service extending FirestoreService
import { FirestoreService } from './FirestoreService'

export class MyNewService extends FirestoreService {
  constructor() {
    super('myCollection')  // Collection name
  }
  
  async customMethod(userId, data) {
    return this.createDocument(userId, data)
  }
}

// Step 2: Export singleton instance
export const myNewService = new MyNewService()

// Step 3: Add to /src/shared/services/firestore/index.js
export { myNewService } from './MyNewService'
```

### 5. Component Communication Pattern
Parent-child communication via props + emits (no direct service access in components):
```vue
<!-- CardStack.vue emits user actions -->
<template>
  <NoteCard @flip="$emit('flip', index)" @swipe="handleSwipe" />
</template>

<!-- SwipeTrainer.vue handles via composables -->
<script setup>
const { markCorrect } = useProgressiveLearning()
async function swipeRight() {
  await markCorrect(cardValue)
}
</script>
```

## Configuration Files

### `/src/config/notes.config.js`
Defines instrument range. Modify for different instruments:
```javascript
export const INSTRUMENT_RANGE = {
  MIN_NOTE: 'E2',    // Classical guitar range
  MAX_NOTE: 'E5',
  MIN_OCTAVE: 2,
  MAX_OCTAVE: 5
}
```

### `/src/shared/utils/constants.js`
Tuning parameters for pitch detection and UI:
- `PITCH_DETECTION.MIN_CLARITY` - Detection sensitivity threshold
- `DETECTION_TIMING.CONFIDENCE_THRESHOLD` - Anti-bounce protection
- CSS custom properties for colors/spacing

## Integration Points

### Firebase Anonymous Auth Flow
1. `App.vue` calls `initAuth()` on mount
2. Creates anonymous user (UID persists in browser)
3. Initializes user document via `userService.initializeUser(uid)`
4. Composables watch `user` ref and load data when available

### Audio Pipeline
```
Microphone → Web Audio API → PitchDetector (Pitchy.js) → 
frequencyToNoteName() → addToDetectionHistory() → 
onNoteDetectedCallback → SwipeTrainer.onNoteDetected() → 
Auto-swipe if match
```

## Common Gotchas

1. **Node.js Version**: Build fails on Node < 20.19. Use `nvm` to switch versions.

2. **Firestore Rules**: Changes to `/firestore.rules` require explicit deploy:
   ```bash
   firebase deploy --only firestore:rules
   ```

3. **Service Initialization**: Composables lazy-init services. Always `await` first call:
   ```javascript
   const { getNextCard } = useProgressiveLearning()
   await getNextCard()  // First call initializes + loads from Firestore
   ```

4. **VexFlow Rendering**: Must call `renderNotation()` on visible cards only:
   ```javascript
   // In CardStack.vue
   nextTick(() => {
     cardRefs[topCardIndex]?.renderNotation()
   })
   ```

5. **State Serialization**: Services with Firestore persistence MUST implement:
   - `serializeState()` - Convert to plain object (no class instances)
   - `_restoreState(state)` - Reconstruct from plain object

## Key Files Reference

- **Entry**: `/src/core/main.js` → `/src/core/App.vue`
- **Main UI**: `/src/features/swipe-trainer/components/SwipeTrainer.vue`
- **Learning Logic**: `/src/services/ProgressiveLearningService.js`
- **Firestore Base**: `/src/shared/services/firestore/FirestoreService.js`
- **Constants**: `/src/shared/utils/constants.js`
- **Docs**: `/LEARNING_ALGORITHM.md`, `/FIRESTORE_INTEGRATION.md`
