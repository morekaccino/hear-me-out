import { createApp } from 'vue'
import '../shared/styles/base.css'
import App from './App.vue'

if (import.meta.env.DEV) {
  import('../services/LeitnerDebugger')
}

createApp(App).mount('#app')

