import { serverTimestamp } from 'firebase/firestore'
import { FirestoreService } from './FirestoreService'

export class UserService extends FirestoreService {
  constructor() {
    super('users')
  }

  async initializeUser(userId) {
    const exists = await this.documentExists(userId)
    
    if (!exists) {
      await this.createDocument(userId, {
        account_created: serverTimestamp()
      })
      console.log('User document created:', userId)
    }
    
    return this.getDocument(userId)
  }

  async updateUserProfile(userId, profileData) {
    return this.updateDocument(userId, profileData)
  }

  async getUserProfile(userId) {
    return this.getDocument(userId)
  }
}

export const userService = new UserService()

