export class LeitnerRepository {
  constructor() {
    this.storageKey = 'leitner-music-notes';
    this.init();
  }

  init() {
    if (!localStorage.getItem(this.storageKey)) {
      const initialData = {
  // Start with octave 4 only; available range will expand slowly within
  // the classical guitar playable range (E2 - B5) which spans octaves 2..5.
  currentOctave: 4,
  maxOctave: 4,
  // Define allowed instrument octave bounds for clarity and enforcement
  minAllowedOctave: 2,
  maxAllowedOctave: 5,
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
    // Only add notes that fall within the classical guitar playable range
    const notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    const data = this.getData();

    // helper to compute an ordering for a note like 'C#4'
    function noteOrder(name) {
      const m = name.match(/^([A-G]#?)(\d+)$/);
      if (!m) return -1;
      const [, ltr, octStr] = m;
      const idx = notes.indexOf(ltr);
      const oct = parseInt(octStr);
      return (oct + 1) * 12 + idx;
    }

    const minNote = 'E2';
    const maxNote = 'B5';

    notes.forEach(note => {
      const noteName = `${note}${octave}`;
      // only include notes that lie within E2..B5
      if (noteOrder(noteName) < noteOrder(minNote) || noteOrder(noteName) > noteOrder(maxNote)) {
        return;
      }

      const noteId = noteName;
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
    // Only expand after the currently-max octave has been mastered.
    // Expansion happens one octave at a time and stays within allowed bounds.
    if (!this.isOctaveMastered(data.maxOctave)) return false;

    const minAllowed = data.minAllowedOctave || 2;
    const maxAllowed = data.maxAllowedOctave || 5;

    // Prefer expanding upward first (higher pitch), one octave at a time
    if (data.maxOctave < maxAllowed) {
      data.maxOctave += 1;
      this.initializeOctaveCards(data.maxOctave);
    } else if (data.currentOctave > minAllowed) {
      // If we've reached the top allowed octave, expand downward slowly
      data.currentOctave -= 1;
      this.initializeOctaveCards(data.currentOctave);
    } else {
      // Nothing to expand
      return false;
    }

    // Record when an octave expansion occurred (store under the octave that triggered it)
    data.stats.octaveMastery[data.maxOctave] = Date.now();
    this.saveData(data);
    return true;
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
