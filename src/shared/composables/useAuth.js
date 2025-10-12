import { ref, onMounted } from 'vue'
import { signInAnonymously, onAuthStateChanged } from 'firebase/auth'
import { auth } from '../../config/firebase.config'

export function useAuth() {
  const user = ref(null)
  const loading = ref(true)
  const error = ref(null)

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
    return new Promise((resolve) => {
      const unsubscribe = onAuthStateChanged(auth, async (currentUser) => {
        if (currentUser) {
          user.value = currentUser
          loading.value = false
          resolve(currentUser)
        } else {
          try {
            const newUser = await loginAnonymously()
            resolve(newUser)
          } catch (err) {
            loading.value = false
            resolve(null)
          }
        }
        unsubscribe()
      })
    })
  }

  return {
    user,
    loading,
    error,
    loginAnonymously,
    initAuth
  }
}

