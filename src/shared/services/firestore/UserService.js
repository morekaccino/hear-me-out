import { serverTimestamp } from 'firebase/firestore'
import { FirestoreService } from './FirestoreService'

export class UserService extends FirestoreService {
  constructor() {
    super('users')
  }

  async initializeUser(userId) {
    console.log('Initializing user:', userId)
    
    try {
      const exists = await this.documentExists(userId)
      console.log('User document exists:', exists)
      
      if (!exists) {
        console.log('Creating new user document...')
        await this.createDocument(userId, {
          account_created: serverTimestamp()
        })
        console.log('User document created:', userId)
      }
      
      const userData = await this.getDocument(userId)
      console.log('User data retrieved:', userData)
      return userData
    } catch (error) {
      console.error('Error in initializeUser:', error)
      console.error('Error code:', error.code)
      console.error('Error message:', error.message)
      throw error
    }
  }

  async updateUserProfile(userId, profileData) {
    return this.updateDocument(userId, profileData)
  }

  async getUserProfile(userId) {
    return this.getDocument(userId)
  }
}

export const userService = new UserService()

