import { doc, getDoc, setDoc, serverTimestamp } from 'firebase/firestore'
import { db } from '../../../config/firebase.config'

export class LearningProgressService {
  constructor() {
    this.collectionName = 'users'
    this.subCollectionName = 'learningProgress'
  }

  _getProgressDocRef(userId) {
    return doc(db, this.collectionName, userId, this.subCollectionName, 'current')
  }

  async saveProgress(userId, progressData) {
    const docRef = this._getProgressDocRef(userId)
    
    await setDoc(docRef, {
      ...progressData,
      updated_at: serverTimestamp()
    }, { merge: true })
  }

  async loadProgress(userId) {
    const docRef = this._getProgressDocRef(userId)
    const docSnap = await getDoc(docRef)
    
    if (docSnap.exists()) {
      return docSnap.data()
    }
    
    return null
  }

  async progressExists(userId) {
    const docRef = this._getProgressDocRef(userId)
    const docSnap = await getDoc(docRef)
    return docSnap.exists()
  }

  async resetProgress(userId) {
    const docRef = this._getProgressDocRef(userId)
    await setDoc(docRef, {
      learningCards: [],
      masteredCards: [],
      stats: {
        totalCorrect: 0,
        totalIncorrect: 0
      },
      updated_at: serverTimestamp(),
      reset_at: serverTimestamp()
    })
  }
}

export const learningProgressService = new LearningProgressService()

