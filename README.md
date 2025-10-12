# 🎵 Music Note Flashcard Trainer

[![Deploy to Firebase Hosting](https://github.com/morekaccino/hear-me-out/actions/workflows/firebase-hosting-merge.yml/badge.svg)](https://github.com/morekaccino/hear-me-out/actions/workflows/firebase-hosting-merge.yml)

An interactive Vue 3 web app that helps musicians practice note recognition using real-time pitch detection with swipeable flashcards.

## 🚀 Live Demo

**[Try it now: https://hearmeout-1995.web.app](https://hearmeout-1995.web.app)**

## 📖 GitHub Repository

**[Source Code: https://github.com/morekaccino/hear-me-out](https://github.com/morekaccino/hear-me-out)**

## Features

### Leitner Spaced Repetition System 🧠
- **Smart Learning Algorithm**: 5-box Leitner system for optimal memorization
- **Adaptive Review Intervals**: Cards reviewed based on mastery level
- **Progress Tracking**: Session stats and performance metrics
- **Persistent Storage**: Your progress is saved locally
- **Swipe-based Feedback**: Right for correct, left for incorrect
- **See [LEITNER_SYSTEM.md](LEITNER_SYSTEM.md) for detailed documentation**

### Interactive Swipe Trainer
- **Interactive Card Stack**: Swipe through musical notes like flashcards
- **Real-time Pitch Detection**: Uses Pitchy.js to detect notes from your microphone
- **VexFlow Notation**: Professional music notation rendering on staff
- **Auto-advance**: Correctly played notes automatically advance to the next card
- **Flip to Reveal**: Tap cards to see the answer
- **Guitar Range**: Notes constrained to classical guitar range (E2-E5)

### User Interface
- **Clean, Modern Design**: Beautiful gradient background with glassmorphism effects
- **Responsive Layout**: Works seamlessly on desktop, tablet, and mobile devices
- **Accessibility Features**: Reduced motion support, proper focus indicators
- **Real-time Feedback**: Visual indicators for microphone status and note detection

## Project Structure

```
src/
├── core/                    # Core application
│   ├── App.vue             # Root component
│   └── main.js             # Application entry point
├── services/                # Application services
│   ├── LeitnerSystemService.js    # Leitner learning algorithm
│   ├── StorageAdapter.js          # Data persistence layer
│   └── LeitnerDebugger.js         # Development debugging tools
├── features/                # Feature modules
│   └── swipe-trainer/       # Main swipe card trainer
│       ├── components/
│       │   ├── SwipeTrainer.vue
│       │   ├── CardStack.vue
│       │   └── NoteCard.vue
│       └── index.js
├── shared/                  # Shared utilities
│   ├── composables/
│   │   ├── usePitchDetection.js
│   │   ├── useNoteGenerator.js
│   │   └── useAuth.js

│   ├── services/
│   │   ├── audio/
│   │   │   └── PitchDetectionService.js
│   │   └── firestore/
│   │       ├── FirestoreService.js
│   │       ├── UserService.js
│   │       └── index.js
│   ├── utils/
│   │   ├── noteConversion.js
│   │   └── constants.js
│   └── styles/
│       ├── variables.css
│       ├── animations.css
│       └── base.css
└── config/
    ├── notes.config.js      # Instrument range configuration
    └── firebase.config.js   # Firebase initialization
```

## How to Use

1. **Start the App**: Microphone initializes automatically
2. **View the Note**: See musical notation on the top card
3. **Play the Note**: Use your instrument to match the displayed note
4. **Auto-advance**: Correct notes automatically swipe right
5. **Manual Feedback**:
   - **Swipe Right →** or sing correctly: Mark as "I know this" (promotes card)
   - **Swipe Left ←**: Mark as "I don't know" (card returns to Box 1)
   - **Tap**: Flip card to see the answer
6. **Track Progress**: View session stats at the bottom of the screen

## Installation & Development

### Prerequisites
- Node.js (v16 or higher)
- A modern web browser with microphone support
- An instrument to practice with (guitar, piano, etc.)

### Setup
```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

### Firebase Setup

The project uses Firebase for authentication and Firestore for data storage.

1. **Create a Firebase Project**:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project or use an existing one

2. **Configure Firebase Credentials**:
   - Update `src/config/firebase.config.js` with your Firebase credentials
   - Get credentials from Firebase Console > Project Settings > General > Your apps

3. **Enable Anonymous Authentication**: 
   - Go to Authentication > Sign-in method
   - Enable "Anonymous" provider
   - This allows users to be automatically logged in without credentials

4. **Setup Firestore Database**:
   - Go to Firestore Database
   - Create database (choose production mode or test mode)
   - Deploy the security rules: `firebase deploy --only firestore:rules`

### Firestore Service Usage

The application includes a service layer for Firestore operations:

#### Base Service: `FirestoreService`

Provides CRUD operations for any Firestore collection:

```javascript
import { FirestoreService } from './shared/services/firestore/FirestoreService'

const notesService = new FirestoreService('notes')
```

**Available Methods:**
- `createDocument(docId, data, merge = true)` - Create or update a document
- `getDocument(docId)` - Get a document by ID
- `updateDocument(docId, data)` - Update existing document
- `documentExists(docId)` - Check if document exists

#### User Service: `UserService`

Specialized service for managing user documents:

```javascript
import { userService } from './shared/services/firestore/UserService'

// Initialize user (creates document if doesn't exist)
await userService.initializeUser(userId)

// Get user profile
const profile = await userService.getUserProfile(userId)

// Update user profile
await userService.updateUserProfile(userId, {
  displayName: 'John Doe',
  level: 5
})
```

**Automatic Timestamps:**
- All documents include `updated_at` (server timestamp)
- User documents include `account_created` timestamp

#### Creating New Services

To create a service for a new collection:

```javascript
import { FirestoreService } from './FirestoreService'

export class ProgressService extends FirestoreService {
  constructor() {
    super('progress') // collection name
  }

  async saveProgress(userId, noteData) {
    return this.createDocument(userId, {
      notes: noteData,
      completedAt: new Date()
    })
  }
}

export const progressService = new ProgressService()
```

### Access the App
- Development: http://localhost:5173/
- The app requires microphone permissions to function
- Users are automatically authenticated anonymously on first visit

## Technical Stack

- **Frontend Framework**: Vue 3 with Composition API & Script Setup
- **Build Tool**: Vite 7.x for fast development and optimized builds
- **Backend**: Firebase (Authentication & Firestore)
- **Pitch Detection**: Pitchy.js (McLeod Pitch Method)
- **Music Notation**: VexFlow 5.x for professional staff rendering
- **Audio Processing**: Web Audio API
- **Styling**: Modern CSS with CSS variables and animations

## Key Technologies

### Audio Processing
- **PitchDetectionService**: Wrapper around Pitchy for consistent pitch detection
- **Web Audio API**: High-quality microphone input processing
- **Frequency Analysis**: Real-time FFT with 4096 sample size

### Data Management
- **FirestoreService**: Base class for CRUD operations on any collection
- **UserService**: Specialized service for user data management
- **Automatic Timestamps**: All documents track updates with `updated_at`

### UI/UX
- **Pointer Events API**: Unified touch/mouse gesture handling
- **CSS Animations**: Smooth transitions and feedback
- **Responsive Design**: Mobile-first approach with breakpoints
- **Glass Morphism**: Modern, semi-transparent UI elements

## Browser Compatibility

- **Chrome/Edge**: Full support ✅
- **Firefox**: Full support ✅
- **Safari**: Full support ✅
- **Mobile Browsers**: Supported (requires HTTPS in production) ✅

## Privacy & Security

- **No Data Collection**: All audio processing happens locally in your browser
- **No External Servers**: No audio data is transmitted anywhere
- **Secure by Default**: Microphone access only used for real-time detection
- **Anonymous Authentication**: Users can practice without creating accounts

## Configuration

### Instrument Range

Edit `/src/config/notes.config.js` to customize:
- Instrument range (min/max notes)
- Playable note pool

```javascript
export const INSTRUMENT_RANGE = {
  MIN_NOTE: 'E2',
  MAX_NOTE: 'E5',
  MIN_OCTAVE: 2,
  MAX_OCTAVE: 5
}
```

### Detection Parameters

Edit `/src/shared/utils/constants.js` to adjust:
- Pitch detection thresholds
- Detection timing parameters
- UI colors and breakpoints

## Development Tools

### Leitner Debugger (Dev Mode Only)

When running in development, the Leitner Debugger is available in the browser console:

```javascript
// View current state
LeitnerDebugger.printCurrentState()

// View box distribution
LeitnerDebugger.printBoxDistribution()

// View stats for specific note
LeitnerDebugger.printCardStats('E2')

// Simulate practice
LeitnerDebugger.simulateCorrectAnswers(5)
LeitnerDebugger.simulateIncorrectAnswers(3)

// Fast forward to next session
LeitnerDebugger.fastForwardToNextSession()

// Export/Import progress
const data = LeitnerDebugger.exportData()
LeitnerDebugger.importData(data)

// Reset all progress
LeitnerDebugger.reset()
```

## Contributing

This project follows modern best practices:
- Feature-based architecture for scalability
- Shared utilities to eliminate duplication
- Composables for reusable logic
- Constants for maintainable configuration
- SOLID principles for service layer

Feel free to:
- Report bugs or suggest improvements
- Fork the project for your own modifications
- Use it as a learning resource for Vue 3 or audio processing

## License

Open source - feel free to use this project for educational purposes.

---

🎼 Happy practicing! Whether you're learning piano, guitar, violin, or any other instrument, this tool will help improve your note recognition skills through interactive learning.
