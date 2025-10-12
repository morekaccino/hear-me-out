import { initializeApp } from 'firebase/app'
import { getAuth } from 'firebase/auth'
import { getFirestore } from 'firebase/firestore'

const firebaseConfig = {
  apiKey: "AIzaSyDd-V29qlWfwQVfxdgX2B97smMX-34EA8A",
  authDomain: "hearmeout-1995.firebaseapp.com",
  projectId: "hearmeout-1995",
  storageBucket: "hearmeout-1995.firebasestorage.app",
  messagingSenderId: "322488809981",
  appId: "1:322488809981:web:a4f79759a796f18ed30194"
}

const app = initializeApp(firebaseConfig)

export const auth = getAuth(app)
export const db = getFirestore(app)
export default app

