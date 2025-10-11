# 🎵 Music Note Flashcard Trainer

[![Deploy to Firebase Hosting](https://github.com/morekaccino/hear-me-out/actions/workflows/firebase-hosting-merge.yml/badge.svg)](https://github.com/morekaccino/hear-me-out/actions/workflows/firebase-hosting-merge.yml)

An interactive Vue 3 web app that helps musicians practice note recognition using real-time pitch detection with swipeable flashcards.

## 🚀 Live Demo

**[Try it now: https://hearmeout-1995.web.app](https://hearmeout-1995.web.app)**

## 📖 GitHub Repository

**[Source Code: https://github.com/morekaccino/hear-me-out](https://github.com/morekaccino/hear-me-out)**

## Features

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
│   │   └── useNoteGenerator.js
│   ├── services/
│   │   └── audio/
│   │       └── PitchDetectionService.js
│   ├── utils/
│   │   ├── noteConversion.js
│   │   └── constants.js
│   └── styles/
│       ├── variables.css
│       ├── animations.css
│       └── base.css
└── config/
    └── notes.config.js      # Instrument range configuration
```

## How to Use

1. **Start the App**: Microphone initializes automatically
2. **View the Note**: See musical notation on the top card
3. **Play the Note**: Use your instrument to match the displayed note
4. **Auto-advance**: Correct notes automatically swipe right
5. **Manual Navigation**: Swipe left/right or tap to flip card

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

### Access the App
- Development: http://localhost:5173/
- The app requires microphone permissions to function

## Technical Stack

- **Frontend Framework**: Vue 3 with Composition API & Script Setup
- **Build Tool**: Vite 7.x for fast development and optimized builds
- **Pitch Detection**: Pitchy.js (McLeod Pitch Method)
- **Music Notation**: VexFlow 5.x for professional staff rendering
- **Audio Processing**: Web Audio API
- **Styling**: Modern CSS with CSS variables and animations

## Key Technologies

### Audio Processing
- **PitchDetectionService**: Wrapper around Pitchy for consistent pitch detection
- **Web Audio API**: High-quality microphone input processing
- **Frequency Analysis**: Real-time FFT with 4096 sample size

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

- **No Data Collection**: All processing happens locally in your browser
- **No External Servers**: No audio data is transmitted anywhere
- **Secure by Default**: Microphone access only used for real-time detection

## Configuration

Edit `/src/config/notes.config.js` to customize:
- Instrument range (min/max notes)
- Playable note pool

Edit `/src/shared/utils/constants.js` to adjust:
- Pitch detection thresholds
- Detection timing parameters
- UI colors and breakpoints

## Contributing

This project follows modern best practices:
- Feature-based architecture for scalability
- Shared utilities to eliminate duplication
- Composables for reusable logic
- Constants for maintainable configuration

Feel free to:
- Report bugs or suggest improvements
- Fork the project for your own modifications
- Use it as a learning resource for Vue 3 or audio processing

## License

Open source - feel free to use this project for educational purposes.

---

🎼 Happy practicing! Whether you're learning piano, guitar, violin, or any other instrument, this tool will help improve your note recognition skills through interactive learning.
