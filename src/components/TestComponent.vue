<template>
  <div style="padding: 2rem; color: white; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh;">
    <h1>🎵 Music Note Flashcard Trainer</h1>
    <p>Test component is working!</p>
    <button @click="count++" style="padding: 1rem; margin: 1rem; background: white; color: black; border: none; border-radius: 8px;">
      Count: {{ count }}
    </button>
    <div v-if="showContent">
      <p>Vue reactive system is working</p>
    </div>
    <button @click="showContent = !showContent" style="padding: 1rem; margin: 1rem; background: white; color: black; border: none; border-radius: 8px;">
      Toggle Content
    </button>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const count = ref(0)
const showContent = ref(true)

console.log('Test component loaded successfully')
</script>
