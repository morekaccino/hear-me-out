<div align="center">

# � Hear Me Out

### *Your Instrument. Your Mic. Your Progress.*

[![Deploy to Firebase](https://github.com/morekaccino/hear-me-out/actions/workflows/firebase-hosting-merge.yml/badge.svg)](https://github.com/morekaccino/hear-me-out/actions/workflows/firebase-hosting-merge.yml)
[![Vue 3](https://img.shields.io/badge/Vue-3.5.18-42b883?logo=vue.js)](https://vuejs.org/)
[![Firebase](https://img.shields.io/badge/Firebase-12.4.0-FFCA28?logo=firebase)](https://firebase.google.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

**[🚀 Try Live Demo](https://hearmeout-1995.web.app)** • **[📖 Documentation](./LEARNING_ALGORITHM.md)** • **[🐛 Report Bug](https://github.com/morekaccino/hear-me-out/issues)** • **[✨ Request Feature](https://github.com/morekaccino/hear-me-out/issues)**

![Hear Me Out Demo](https://via.placeholder.com/800x400/667eea/ffffff?text=🎵+Play+Your+Instrument+→+See+Real-Time+Recognition)

*Swipe, play, learn. Master music notation with real-time audio feedback and intelligent spaced repetition.*

</div>

---

## 🌟 What Makes This Special?

Ever wondered if you could learn music theory by actually **playing** instead of just reading? That's exactly what Hear Me Out does. Pick up your guitar, violin, or any instrument, and watch as the app **listens** to you play and guides your learning journey.

### 🎯 The Problem We Solve

- 📚 Traditional flashcards are boring and disconnected from real practice
- 🎼 Reading sheet music is one thing, *playing* it is another
- 🔄 You never know if you're practicing the right notes at the right time
- 📊 Tracking progress manually is tedious and demotivating

### ✨ Our Solution

<table>
<tr>
<td width="50%">

**🎤 Real-Time Pitch Detection**  
Play any note on your instrument and get instant feedback. Uses advanced McLeod Pitch Method for accurate recognition.

**🧠 Smart Learning Algorithm**  
Progressive learning system that introduces notes gradually and reviews them at optimal intervals for maximum retention.

</td>
<td width="50%">

**💫 Swipeable Flashcards**  
Familiar Tinder-like interface. Swipe right if you know it, left if you need more practice. Or just play the note and watch it auto-advance!

**☁️ Cloud Progress Sync**  
Your progress follows you everywhere. Practice on your phone during lunch, continue on your desktop at home.

</td>
</tr>
</table>

---

## 🎬 See It In Action

<div align="center">

| 🎸 Play Your Instrument | 🎯 Get Instant Feedback | 📈 Track Your Progress |
|:---:|:---:|:---:|
| ![Play](https://via.placeholder.com/250x200/667eea/ffffff?text=🎸+PLAY) | ![Feedback](https://via.placeholder.com/250x200/764ba2/ffffff?text=✓+CORRECT) | ![Progress](https://via.placeholder.com/250x200/f093fb/ffffff?text=📊+STATS) |

</div>

---

## 🚀 Features That'll Make You Go "Wow!"

### 🧠 Leitner Spaced Repetition System

Not all flashcard apps are created equal. We use a **progressive learning algorithm** that:

```
New Note → Practice 2x → Master 3x → Periodic Review (70% chance)
                ↓                          ↓
         Only introduces next note when ready
```

- 🎯 **Conservative Introduction**: Only 1 new card at a time - no overwhelming
- 🔄 **Adaptive Review Intervals**: Cards pop up exactly when your brain needs them
- 📊 **Real-time Stats**: Watch your mastery percentage grow in real-time
- 💾 **Auto-Save Progress**: Every action syncs to the cloud (500ms debounce for performance)
- 🎮 **Gamified Feedback**: Swipe right for "I got this!", left for "Need more practice"

> 💡 **Pro Tip**: The algorithm waits until you've mastered current notes before introducing new ones. Quality over quantity!

### 🎤 Real-Time Pitch Detection That Actually Works

Forget those laggy tuner apps. Our detection system features:

- ⚡ **Sub-400ms Response**: Lightning-fast recognition with anti-bounce protection
- 🎸 **Multi-Instrument Support**: Guitar, piano, violin, vocals - if it makes sound, we detect it
- 🎼 **Professional Notation**: VexFlow rendering for crystal-clear staff notation
- 🚫 **Smart Filtering**: Confidence threshold system prevents false positives
- 🎯 **Auto-Advance**: Play the right note and boom - automatic swipe right

**Technical Flex**: We use the McLeod Pitch Method (MPM) with history-based confidence scoring. Translation? Industry-grade accuracy.

### 💅 UI/UX That Doesn't Suck

<details>
<summary><strong>Click to see what makes our interface special</strong></summary>

- 🎨 **Glassmorphism Design**: Beautiful gradient backgrounds with blur effects
- 📱 **True Responsive**: Butter-smooth on everything from phones to 4K monitors
- ♿ **Accessibility First**: Reduced motion support, keyboard navigation, screen reader friendly
- 🎭 **Micro-interactions**: Every swipe, tap, and gesture feels *chef's kiss*
- 🌙 **Eye-Friendly**: Carefully chosen colors that won't strain your eyes during long practice sessions

</details>

### ☁️ Firebase-Powered Backend

- 👤 **Anonymous Auth**: Start practicing immediately, no signup BS
- 💾 **Firestore Sync**: Progress saved across all your devices
- 🔒 **Secure by Design**: Your data, your control, no tracking
- 🚀 **Blazing Fast**: Edge-cached for sub-100ms response times worldwide

---

## 🏗️ Architecture (For the Nerds Among Us)

This isn't just "works on my machine" code. We follow **SOLID principles** with a **feature-based architecture**:

<details>
<summary><strong>📂 Project Structure (Click to expand)</strong></summary>

```
src/
├── core/                          # 🎯 Application entry point
│   ├── App.vue                   # Root component with auth flow
│   └── main.js                   # Vue 3 + Firebase initialization
│
├── services/                      # 🧠 Business logic (stateful services)
│   ├── ProgressiveLearningService.js  # Smart card introduction algorithm
│   ├── LeitnerSystemService.js        # Alternative spaced repetition
│   ├── StorageAdapter.js              # Abstraction over storage backends
│   └── LeitnerDebugger.js             # Dev tools (console debugging)
│
├── features/                      # 🎨 Feature modules (self-contained)
│   └── swipe-trainer/
│       ├── components/
│       │   ├── SwipeTrainer.vue       # Main orchestrator
│       │   ├── CardStack.vue          # 3D card stack renderer
│       │   └── NoteCard.vue           # Individual flashcard
│       └── index.js
│
├── shared/                        # 🔧 Reusable utilities
│   ├── composables/               # Vue 3 composition functions
│   │   ├── usePitchDetection.js   # Audio processing bridge
│   │   ├── useProgressiveLearning.js  # Learning algorithm + Firebase
│   │   ├── useAuth.js             # Anonymous auth wrapper
│   │   └── useNoteGenerator.js    # Random note generation
│   │
│   ├── services/
│   │   ├── audio/
│   │   │   └── PitchDetectionService.js  # Pitchy.js wrapper
│   │   └── firestore/
│   │       ├── FirestoreService.js       # Base CRUD service
│   │       ├── LearningProgressService.js
│   │       └── UserService.js
│   │
│   ├── utils/
│   │   ├── noteConversion.js      # Frequency ↔ Note conversion
│   │   └── constants.js           # Tuning parameters
│   │
│   └── styles/                    # 🎨 Global styles
│       ├── variables.css          # CSS custom properties
│       ├── animations.css         # Keyframes & transitions
│       └── base.css               # Resets & typography
│
└── config/                        # ⚙️ Configuration files
    ├── notes.config.js            # Instrument range (E2-E5 for guitar)
    └── firebase.config.js         # Firebase credentials

```

**Key Patterns:**
- 🎯 **Service Layer Pattern**: Business logic in services, NOT components
- 🔌 **Composables as Bridges**: Orchestrate services + Firebase + Vue reactivity
- 💾 **Firestore Service Inheritance**: DRY CRUD operations with base class
- 🎨 **Feature-Based Structure**: Self-contained, scalable modules

</details>

---

## 🎮 How to Use (It's Dead Simple)

1. 🌐 **Open the app** → Mic initializes automatically (grant permission when prompted)
2. 🎼 **See a note** → Staff notation appears on the top card
3. 🎸 **Play it** → Use your instrument to match the note
4. ✨ **Watch the magic** → Correct notes auto-swipe right!

### 🕹️ Controls

| Action | Method | Result |
|:---:|:---:|:---:|
| 👍 Know this! | Swipe right **OR** play correctly | Card promoted to next mastery level |
| 👎 Need practice | Swipe left | Card returns to learning pool |
| 🔄 Reveal answer | Tap/click card | Flip to see note name |
| 📊 View stats | Scroll down | Session metrics & progress |

> **💡 Pro Tip**: You can switch between manual swiping and auto-detection anytime. Mixed mode ftw!

---

## 🛠️ Installation & Development

### Prerequisites

| Required | Version | Why? |
|:---:|:---:|---|
| 🟢 **Node.js** | 20.19+ or 22.12+ | Vite 7 requirement |
| 🎤 **Microphone** | Any | Real-time pitch detection |
| 🎸 **Instrument** | Guitar, piano, vocals, etc. | The fun part! |
| 🌐 **Browser** | Chrome/Firefox/Safari (latest) | Web Audio API support |

### 🚀 Quick Start

```bash
# 1️⃣ Clone the repo
git clone https://github.com/morekaccino/hear-me-out.git
cd hear-me-out

# 2️⃣ Install dependencies
npm install

# 3️⃣ Start the dev server
npm run dev

# 🎉 Open http://localhost:5173 and start jamming!
```

### 📦 Production Build

```bash
# Build optimized production bundle
npm run build

# Preview the build locally
npm run preview
```

### ☁️ Firebase Setup (Optional but Recommended)

<details>
<summary><strong>Click here for Firebase configuration steps</strong></summary>

#### 1️⃣ Create Firebase Project
- Go to [Firebase Console](https://console.firebase.google.com/)
- Click **Add Project** → Follow the wizard

#### 2️⃣ Configure Credentials
```javascript
// src/config/firebase.config.js
export const firebaseConfig = {
  apiKey: "YOUR_API_KEY",
  authDomain: "YOUR_PROJECT.firebaseapp.com",
  projectId: "YOUR_PROJECT_ID",
  storageBucket: "YOUR_PROJECT.appspot.com",
  messagingSenderId: "YOUR_SENDER_ID",
  appId: "YOUR_APP_ID"
}
```

#### 3️⃣ Enable Anonymous Auth
- Firebase Console → **Authentication** → **Sign-in method**
- Enable **Anonymous** provider
- No email/password needed = frictionless onboarding 🎉

#### 4️⃣ Setup Firestore
```bash
# Create database in Firebase Console (test mode is fine for dev)
# Then deploy security rules:
firebase deploy --only firestore:rules
```

**Why Firebase?**
- ✅ Cross-device sync (practice on phone, continue on desktop)
- ✅ Offline support out of the box
- ✅ No backend code to maintain
- ✅ Free tier covers thousands of users

</details>

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

---

## 🧰 Tech Stack (The Good Stuff)

<div align="center">

| Layer | Technology | Why We Chose It |
|:---:|:---:|---|
| 🎨 **Frontend** | Vue 3 (Composition API) | Reactive, lightweight, `<script setup>` syntax is 🔥 |
| ⚡ **Build Tool** | Vite 7.x | Sub-second HMR, 10x faster than Webpack |
| ☁️ **Backend** | Firebase | Serverless, real-time sync, free tier is generous |
| 🎤 **Pitch Detection** | Pitchy.js | McLeod Pitch Method = industry standard accuracy |
| 🎼 **Music Notation** | VexFlow 5.x | Professional-grade engraving engine |
| 🔊 **Audio** | Web Audio API | Native browser support, zero dependencies |
| 💅 **Styling** | Modern CSS | Variables, animations, glassmorphism effects |

</div>

### 🎯 Key Technical Achievements

- **Sub-400ms Pitch Detection**: Custom anti-bounce algorithm with confidence scoring
- **Auto-Save Debouncing**: 500ms intelligent debounce prevents Firestore quota burn
- **Service Layer Architecture**: Business logic isolated from UI (testable AF)
- **Progressive Enhancement**: Works offline, syncs when online
- **Zero NPM Vulnerabilities**: All dependencies actively maintained

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

## 🌐 Browser Compatibility

<div align="center">

| Browser | Status | Notes |
|:---:|:---:|---|
| 🟢 **Chrome** | ✅ Full Support | Recommended for best performance |
| 🟢 **Edge** | ✅ Full Support | Chromium-based = same as Chrome |
| 🟢 **Firefox** | ✅ Full Support | Web Audio API works great |
| 🟢 **Safari** | ✅ Full Support | Desktop & iOS (requires HTTPS) |
| 📱 **Mobile** | ✅ Supported | HTTPS required for mic access |

</div>

**Minimum Requirements:**
- ECMAScript 2020 (ES11) support
- Web Audio API
- Microphone access permission

## 🔒 Privacy & Security

We take your privacy seriously. Here's what we **DON'T** do:

❌ **NO audio recording** - Everything processed in real-time  
❌ **NO audio uploads** - Your sound never leaves your device  
❌ **NO tracking cookies** - We literally don't care where you go  
❌ **NO email signup** - Anonymous auth = zero spam  
❌ **NO data selling** - There's nothing to sell!  

Here's what we **DO** do:

✅ **Local processing** - All pitch detection in your browser  
✅ **Encrypted sync** - Progress data encrypted in transit (HTTPS/TLS)  
✅ **Anonymous by default** - No PII collected, ever  
✅ **Open source** - Audit the code yourself!  

**Firestore Data Stored:**
- User ID (anonymous Firebase UID)
- Learning progress (which notes you've mastered)
- Session stats (timestamps, success rates)

That's it. No names, emails, or creepy tracking.

---

## ⚙️ Configuration & Customization

### 🎸 Instrument Range

Want to use this for bass? Flute? Opera singing? Easy:

```javascript
// src/config/notes.config.js
export const INSTRUMENT_RANGE = {
  MIN_NOTE: 'E2',    // 🎸 Classical guitar range
  MAX_NOTE: 'E5',    // Change these for your instrument!
  MIN_OCTAVE: 2,
  MAX_OCTAVE: 5
}
```

**Common Presets:**
- 🎹 Piano: `A0` to `C8` (full 88-key range)
- 🎻 Violin: `G3` to `E7`
- 🎤 Male vocals: `E2` to `E4`
- 🎤 Female vocals: `C4` to `C6`
- 🎺 Trumpet: `F#3` to `D6`

### 🎚️ Fine-Tuning Detection

```javascript
// src/shared/utils/constants.js
export const PITCH_DETECTION = {
  MIN_CLARITY: 0.92,              // Higher = stricter detection
  CONFIDENCE_THRESHOLD: 3,        // Detections needed for confidence
  HISTORY_WINDOW_MS: 400,         // Time window for history
  REFRACTORY_MS: 2000,           // Cooldown after detection
  SILENCE_FRAMES_TO_REARM: 10    // Silence needed to reset
}
```

**Tuning Guide:**
- 🎯 Too many false positives? → Increase `MIN_CLARITY` to `0.95`
- 🐌 Too slow to respond? → Decrease `CONFIDENCE_THRESHOLD` to `2`
- 🏃 Too sensitive? → Increase `REFRACTORY_MS` to `3000`

---

## 🛠️ Developer Tools (Hidden Gems)

### 🔍 Leitner Debugger (Dev Mode Only)

Open your browser console and access the global `LeitnerDebugger` object for X-ray vision into the learning algorithm:

<details>
<summary><strong>Click to see all debugger commands</strong></summary>

```javascript
// 📊 Inspect current state
LeitnerDebugger.printCurrentState()
// Output: Total cards, review schedule, mastery distribution

// 📦 See box distribution
LeitnerDebugger.printBoxDistribution()
// Output: How many cards in each Leitner box

// 🎵 Stats for specific note
LeitnerDebugger.printCardStats('E2')
// Output: Attempts, success rate, current box

// 🎮 Simulate practice sessions
LeitnerDebugger.simulateCorrectAnswers(5)
LeitnerDebugger.simulateIncorrectAnswers(3)

// ⏩ Time travel (for testing)
LeitnerDebugger.fastForwardToNextSession()

// 💾 Export/Import progress
const backup = LeitnerDebugger.exportData()
LeitnerDebugger.importData(backup)

// 🔄 Nuclear option
LeitnerDebugger.reset()
```

**Use Cases:**
- 🐛 Debug algorithm behavior
- 🧪 Test edge cases without playing 100 notes
- 📸 Create demo states for screenshots
- 🎓 Learn how spaced repetition works under the hood

</details>

---

## 🤝 Contributing

**We love contributions!** Whether you're fixing a typo or architecting a new feature, all PRs are welcome.

### 🌟 Ways to Contribute

- 🐛 **Report bugs** - Found something broken? [Open an issue](https://github.com/morekaccino/hear-me-out/issues)
- 💡 **Suggest features** - Got ideas? We're all ears!
- 📝 **Improve docs** - Typos, clarity, examples - all appreciated
- 🎨 **Design improvements** - UI/UX suggestions welcome
- 🧪 **Add tests** - Help us maintain quality
- 🌍 **Translations** - Want this in your language?

### 🚀 Development Workflow

```bash
# 1. Fork & clone
git clone https://github.com/YOUR_USERNAME/hear-me-out.git

# 2. Create feature branch
git checkout -b feature/amazing-feature

# 3. Make your changes & commit
git commit -m "Add amazing feature"

# 4. Push & create PR
git push origin feature/amazing-feature
```

**Code Standards:**
- ✅ Vue 3 Composition API (no Options API)
- ✅ Service layer for business logic
- ✅ Composables for Vue integration
- ✅ Clear, descriptive variable names
- ✅ Comments for complex algorithms

---

## 📄 License

**MIT License** - Do whatever you want! Commercial use? Go for it. Fork and sell? Sure. Just don't blame us if it breaks. 😉

See [LICENSE](LICENSE) file for full legalese.

---

## 💖 Acknowledgments

- **Pitchy.js** - For the amazing pitch detection library
- **VexFlow** - For professional music notation
- **Vue.js Team** - For making reactive UI actually fun
- **Firebase** - For the serverless backend
- **YOU** - For checking out this project! ⭐

---

<div align="center">

## 🎸 Ready to Rock?

[![Try Live Demo](https://img.shields.io/badge/🚀_Try_Live_Demo-667eea?style=for-the-badge&logoColor=white)](https://hearmeout-1995.web.app)
[![Star on GitHub](https://img.shields.io/badge/⭐_Star_on_GitHub-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/morekaccino/hear-me-out)

### Made with 💜 by musicians, for musicians

*If this project helped you, consider giving it a ⭐ - it means a lot!*

**Questions?** Open an issue. **Ideas?** Start a discussion. **Just want to chat?** Find me on GitHub!

</div>

---

<div align="center">
<sub>Built with Vue 3 🚀 • Powered by Firebase ☁️ • Detecting pitches since 2025 🎵</sub>
</div>
