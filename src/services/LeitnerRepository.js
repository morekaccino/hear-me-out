export class LeitnerRepository {
  constructor() {
    this.storageKey = 'leitner-music-notes';
    this.init();
  }

  init() {
    if (!localStorage.getItem(this.storageKey)) {
      const initialData = {
        currentOctave: 4, // Start with octave 4 (middle C)
        maxOctave: 4,     // Only allow octave 4 initially
        boxes: {
          1: [], // New cards
          2: [], // Review after 1 day
          3: [], // Review after 3 days
          4: [], // Review after 1 week
          5: []  // Mastered cards
        },
        stats: {
          totalCorrect: 0,
          totalAttempts: 0,
          octaveMastery: {} // Track mastery per octave
        }
      };
      this.saveData(initialData);
    }
  }

  getData() {
    return JSON.parse(localStorage.getItem(this.storageKey));
  }

  saveData(data) {
    localStorage.setItem(this.storageKey, JSON.stringify(data));
  }

  // Initialize cards for current octave only
  initializeOctaveCards(octave) {
    const notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    const data = this.getData();
    
    notes.forEach(note => {
      const noteId = `${note}${octave}`;
      const existsInAnyBox = Object.values(data.boxes).some(box => 
        box.some(card => card.id === noteId)
      );
      
      if (!existsInAnyBox) {
        data.boxes[1].push({
          id: noteId,
          note: note,
          octave: octave,
          attempts: 0,
          correct: 0,
          lastReview: null,
          nextReview: Date.now(),
          box: 1
        });
      }
    });
    
    this.saveData(data);
  }

  // Check if current octave is mastered (80% success rate, minimum 5 attempts per note)
  isOctaveMastered(octave) {
    const data = this.getData();
    const octaveCards = Object.values(data.boxes).flat()
      .filter(card => card.octave === octave);
    
    if (octaveCards.length === 0) return false;
    
    const masteredCards = octaveCards.filter(card => {
      return card.attempts >= 5 && (card.correct / card.attempts) >= 0.8;
    });
    
    return masteredCards.length === octaveCards.length;
  }

  // Expand to next octave when current is mastered
  expandOctaveRange() {
    const data = this.getData();
    
    if (this.isOctaveMastered(data.maxOctave)) {
      // Expand up first, then down
      if (data.maxOctave < 6) {
        data.maxOctave += 1;
        this.initializeOctaveCards(data.maxOctave);
      } else if (data.currentOctave > 2) {
        data.currentOctave -= 1;
        this.initializeOctaveCards(data.currentOctave);
      }
      
      data.stats.octaveMastery[data.currentOctave] = Date.now();
      this.saveData(data);
      return true;
    }
    
    return false;
  }

  getAvailableOctaves() {
    const data = this.getData();
    const octaves = [];
    for (let i = data.currentOctave; i <= data.maxOctave; i++) {
      octaves.push(i);
    }
    return octaves;
  }

  reset() {
    localStorage.removeItem(this.storageKey);
    this.init();
  }
}
