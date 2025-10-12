import { auth, db } from '../../config/firebase.config'

export function useFirebase() {
  return {
    auth,
    db
  }
}

