# Firestore Integration for Learning Progress

This document explains the Firestore persistence integration for the progressive learning system.

## Overview

The learning progress is now automatically saved to Firestore, allowing users to:
- Resume their learning sessions across browser refreshes
- Continue learning on different devices (with same anonymous user)
- Never lose progress

## Architecture

### Service Layer

#### `LearningProgressService` (`/src/shared/services/firestore/LearningProgressService.js`)

Handles all Firestore operations for learning progress:

```javascript
class LearningProgressService {
  async saveProgress(userId, progressData)
  async loadProgress(userId)
  async progressExists(userId)
  async resetProgress(userId)
}
```

**Firestore Path**: `/users/{userId}/learningProgress/current`

### Business Logic Layer

#### `ProgressiveLearningService` (`/src/services/ProgressiveLearningService.js`)

Enhanced with serialization/deserialization:

- `serializeState()`: Converts internal state to Firestore-compatible format
- `_restoreState(state)`: Restores state from Firestore data
- Constructor accepts `initialState` parameter for restoration

### Composable Layer

#### `useProgressiveLearning` (`/src/shared/composables/useProgressiveLearning.js`)

Orchestrates authentication, loading, and auto-saving:

1. **Initialization**:
   - Automatically initializes Firebase Auth
   - Loads saved progress for authenticated user
   - Falls back to new session if no saved data

2. **Auto-Save**:
   - Saves progress after every correct/incorrect answer
   - Debounced by 500ms to reduce Firestore writes
   - Non-blocking (async)

3. **User Switching**:
   - Watches for user changes
   - Automatically loads new user's progress

## Data Structure

### Firestore Document

```javascript
{
  learningCards: [
    {
      noteValue: "E2",
      correctStreak: 2,
      totalCorrect: 3,
      totalIncorrect: 1,
      lastSeen: 1634567890123
    }
  ],
  masteredCards: [
    {
      noteValue: "F2",
      correctStreak: 3,
      totalCorrect: 5,
      totalIncorrect: 0,
      lastSeen: 1634567890123,
      masteredAt: 1634567890000,
      reviewCount: 2
    }
  ],
  cardIdCounter: 15,
  stats: {
    totalCorrect: 8,
    totalIncorrect: 1,
    accuracy: 89,
    total: 37,
    learning: 3,
    mastered: 5,
    notStarted: 29,
    progressPercentage: 20
  },
  updated_at: <Firestore Timestamp>
}
```

## Security Rules

Updated Firestore rules ensure users can only access their own data:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /learningProgress/{progressId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

## Flow Diagram

```
User Opens App
     ↓
App.vue mounts
     ↓
initAuth() → Anonymous Auth
     ↓
User authenticated with UID
     ↓
useProgressiveLearning composable
     ↓
loadProgress(userId) from Firestore
     ↓
ProgressiveLearningService initialized with saved state
     ↓
User interacts (swipe right/left)
     ↓
markCorrect() / markIncorrect()
     ↓
Update internal state
     ↓
saveProgress(userId) [debounced 500ms]
     ↓
Progress saved to Firestore
```

## Key Features

### 1. **Automatic Authentication**
- Uses Firebase Anonymous Authentication
- Transparent to user (no login required)
- Persistent across sessions via browser storage

### 2. **Seamless Persistence**
- No manual save buttons
- Progress saved after every interaction
- Debounced to optimize Firestore writes

### 3. **State Recovery**
- Automatically loads saved state on app start
- Validates and sanitizes loaded data
- Falls back gracefully if data is corrupted

### 4. **Optimized Writes**
- 500ms debounce prevents excessive writes
- Only saves when state actually changes
- Uses Firestore merge for partial updates

### 5. **Cross-Device Support**
- Same anonymous user ID works across devices
- Progress syncs automatically
- Last write wins (no conflict resolution needed for single-user scenario)

## Error Handling

The system gracefully handles:
- No internet connection (operations queued by Firestore SDK)
- Authentication failures (falls back to local-only mode)
- Missing or corrupted data (initializes fresh state)
- Firestore permission errors (logs error, continues with local state)

## Testing Locally

1. **Check Authentication**:
   ```javascript
   // In browser console
   firebase.auth().currentUser
   // Should show user with UID
   ```

2. **Check Firestore Data**:
   - Open Firebase Console
   - Navigate to Firestore Database
   - Look for `/users/{uid}/learningProgress/current`

3. **Test Persistence**:
   - Answer a few cards
   - Wait 1 second (for debounced save)
   - Refresh page
   - Progress should be maintained

## Cost Considerations

### Firestore Operations

- **Reads**: 1 per app load (per user)
- **Writes**: ~1 per 0.5 seconds of active usage
- **Storage**: ~1-2 KB per user

### Estimated Costs (Free Tier)

Free tier includes:
- 50,000 reads/day
- 20,000 writes/day
- 1 GB storage

For a typical user:
- 1 read per session
- ~120 writes per hour of active use
- Negligible storage

This means the free tier supports:
- 50,000 daily active users (reads)
- 166 hours of total active usage per day (writes)

## Future Enhancements

Potential improvements:
1. Batch writes for multiple rapid interactions
2. Offline support with conflict resolution
3. Progress history/analytics
4. Cross-device real-time sync
5. Data export functionality
6. Progress sharing/comparison features

## Troubleshooting

### Progress Not Saving

1. Check browser console for errors
2. Verify user is authenticated: `firebase.auth().currentUser`
3. Check Firestore rules are deployed
4. Verify internet connection

### Progress Not Loading

1. Check if data exists in Firestore console
2. Verify user UID matches
3. Check for serialization errors in console
4. Try resetting progress (if data is corrupted)

### "Permission Denied" Errors

1. Ensure Firestore rules are deployed: `firebase deploy --only firestore:rules`
2. Verify user is authenticated
3. Check rule conditions match your user's UID

## Related Files

- `/src/shared/services/firestore/LearningProgressService.js` - Firestore service
- `/src/services/ProgressiveLearningService.js` - Learning algorithm with serialization
- `/src/shared/composables/useProgressiveLearning.js` - Vue composable with auto-save
- `/firestore.rules` - Security rules
- `/LEARNING_ALGORITHM.md` - Algorithm documentation

