const STORAGE_KEY = 'leitner_system_data'

export class StorageAdapter {
  save(data) {
    try {
      const serialized = JSON.stringify(data)
      localStorage.setItem(STORAGE_KEY, serialized)
    } catch (error) {
      console.error('Failed to save Leitner data:', error)
    }
  }

  load() {
    try {
      const serialized = localStorage.getItem(STORAGE_KEY)
      if (!serialized) return null
      return JSON.parse(serialized)
    } catch (error) {
      console.error('Failed to load Leitner data:', error)
      return null
    }
  }

  clear() {
    try {
      localStorage.removeItem(STORAGE_KEY)
    } catch (error) {
      console.error('Failed to clear Leitner data:', error)
    }
  }
}

export class FirestoreAdapter extends StorageAdapter {
  constructor(firestoreDb, userId) {
    super()
    this.db = firestoreDb
    this.userId = userId
  }

  async save(data) {
    throw new Error('FirestoreAdapter not yet implemented')
  }

  async load() {
    throw new Error('FirestoreAdapter not yet implemented')
  }

  async clear() {
    throw new Error('FirestoreAdapter not yet implemented')
  }
}

