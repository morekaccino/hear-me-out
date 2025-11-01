import { ref, onMounted } from 'vue'
import { signInAnonymously, onAuthStateChanged } from 'firebase/auth'
import { auth } from '../../config/firebase.config'

// Shared state across all instances of useAuth
const user = ref(null)
const loading = ref(true)
const error = ref(null)
let initPromise = null

export function useAuth() {
  const loginAnonymously = async () => {
    try {
      loading.value = true
      error.value = null
      const result = await signInAnonymously(auth)
      user.value = result.user
      return result.user
    } catch (err) {
      error.value = err.message
      console.error('Anonymous login failed:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  const initAuth = () => {
    // Return cached promise if already initializing/initialized
    if (initPromise) {
      console.log('Returning cached auth promise')
      return initPromise
    }

    initPromise = new Promise((resolve) => {
      const unsubscribe = onAuthStateChanged(auth, async (currentUser) => {
        console.log('Auth state changed:', currentUser ? currentUser.uid : 'no user')
        if (currentUser) {
          console.log('User already authenticated:', currentUser.uid)
          console.log('Is anonymous:', currentUser.isAnonymous)
          user.value = currentUser
          loading.value = false
          resolve(currentUser)
        } else {
          console.log('No user found, signing in anonymously...')
          try {
            const newUser = await loginAnonymously()
            console.log('Anonymous sign in successful:', newUser?.uid)
            resolve(newUser)
          } catch (err) {
            console.error('Anonymous sign in failed:', err)
            loading.value = false
            resolve(null)
          }
        }
        unsubscribe()
      })
    })

    return initPromise
  }

  return {
    user,
    loading,
    error,
    loginAnonymously,
    initAuth
  }
}

