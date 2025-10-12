import { doc, setDoc, getDoc, updateDoc, serverTimestamp } from 'firebase/firestore'
import { db } from '../../../config/firebase.config'

export class FirestoreService {
  constructor(collectionName) {
    this.collectionName = collectionName
  }

  async createDocument(docId, data, merge = true) {
    await setDoc(doc(db, this.collectionName, docId), {
      ...data,
      updated_at: serverTimestamp()
    }, { merge })
  }

  async getDocument(docId) {
    const docSnap = await getDoc(doc(db, this.collectionName, docId))
    return docSnap.exists() ? docSnap.data() : null
  }

  async updateDocument(docId, data) {
    await updateDoc(doc(db, this.collectionName, docId), {
      ...data,
      updated_at: serverTimestamp()
    })
  }

  async documentExists(docId) {
    const docSnap = await getDoc(doc(db, this.collectionName, docId))
    return docSnap.exists()
  }
}

