# 🎵 Music Note Flashcard Trainer

[![Deploy to Firebase Hosting](https://github.com/morekaccino/hear-me-out/actions/workflows/firebase-hosting-merge.yml/badge.svg)](https://github.com/morekaccino/hear-me-out/actions/workflows/firebase-hosting-merge.yml)

An interactive Vue 3 web app that helps musicians practice note recognition using real-time pitch detection.

## 🚀 Live Demo

**[Try it now: https://hearmeout-1995.web.app](https://hearmeout-1995.web.app)**

## 📖 GitHub Repository

**[Source Code: https://github.com/morekaccino/hear-me-out](https://github.com/morekaccino/hear-me-out)**

## Features

### Core Functionality
- **Random Note Display**: Shows musical notes that you need to play
- **Real-time Pitch Detection**: Uses Pitchy.js (McLeod Pitch Method) to detect notes from your microphone
- **Dual Display Modes**: Toggle between musical notation symbols (Bravura font) and letter notation
- **Accurate Note Matching**: Compares detected pitch with target note within ±50 cents tolerance
- **Score Tracking**: Keeps track of correct answers and accuracy percentage

### User Interface
- **Clean, Modern Design**: Beautiful gradient background with glassmorphism effects
- **Responsive Layout**: Works seamlessly on desktop and mobile devices
- **Accessibility Features**: Proper focus indicators and reduced motion support
- **Real-time Feedback**: Instant visual feedback when notes are matched correctly

### Technical Features
- **Advanced Audio Processing**: Uses Web Audio API for high-quality microphone input
- **Musical Font Support**: Bravura font for professional music notation display
- **Frequency Analysis**: Real-time frequency-to-note conversion with precise tuning
- **Configurable Settings**: Adjustable volume thresholds and clarity requirements

## How to Use

1. **Start the App**: Click "Initialize Mic" to set up microphone access
2. **Begin Practice**: Click "Start Listening" to begin the exercise
3. **Play the Note**: Look at the displayed note and play it on your instrument
4. **Get Feedback**: The app will detect your pitch and provide immediate feedback
5. **Continue Learning**: Successfully matched notes automatically generate new challenges
6. **Track Progress**: Monitor your accuracy and improvement over time

## Display Modes

### Symbol Mode
- Shows professional musical notation using the Bravura font
- Displays note heads with proper accidentals (♯/♭)
- Provides authentic music reading experience

### Letter Mode  
- Shows note names in clear, large text (e.g., "A4", "C#3", "Bb5")
- Perfect for beginners or quick reference
- Easy to read on any device

## Installation & Development

### Prerequisites
- Node.js (v16 or higher)
- A modern web browser with microphone support
- An instrument to practice with

### Setup
```bash
# Clone or download the project
cd hear_me_out

# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build
```

### Access the App
- Development: http://localhost:5173/
- The app requires microphone permissions to function

## Technical Stack

- **Frontend Framework**: Vue 3 with Composition API
- **Build Tool**: Vite for fast development and optimized builds
- **Pitch Detection**: Pitchy.js (McLeod Pitch Method)
- **Audio Processing**: Web Audio API
- **Typography**: Bravura music font for notation symbols
- **Styling**: Modern CSS with custom properties and responsive design

## Browser Compatibility

- **Chrome/Edge**: Full support
- **Firefox**: Full support  
- **Safari**: Full support
- **Mobile Browsers**: Supported (requires HTTPS in production)

## Privacy & Security

- **No Data Collection**: All processing happens locally in your browser
- **No External Servers**: No audio data is transmitted anywhere
- **Secure by Default**: Microphone access is only used for real-time pitch detection

## Contributing

This project was created as a complete music education tool. Feel free to:
- Report bugs or suggest improvements
- Fork the project for your own modifications
- Use it as a learning resource for Vue 3 or audio processing

## License

Open source - feel free to use this project for educational purposes.

---

🎼 Happy practicing! Whether you're learning piano, guitar, violin, or any other instrument, this tool will help improve your note recognition skills.
