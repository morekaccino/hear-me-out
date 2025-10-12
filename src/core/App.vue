<script setup>
import { onMounted } from 'vue'
import { SwipeTrainer } from '../features/swipe-trainer'
import { useAuth } from '../shared/composables/useAuth'
import { userService } from '../shared/services/firestore/UserService'

const { user, loading, initAuth } = useAuth()

onMounted(async () => {
  const authenticatedUser = await initAuth()
  if (authenticatedUser) {
    console.log('User authenticated:', authenticatedUser.uid)
    await userService.initializeUser(authenticatedUser.uid)
  }
})
</script>

<template>
  <SwipeTrainer />
</template>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
  overflow-x: hidden;
}

button {
  border: none;
  background: none;
  font-family: inherit;
}

button:focus {
  outline: 2px solid rgba(255, 255, 255, 0.5);
  outline-offset: 2px;
}

input:focus {
  outline: 2px solid rgba(255, 255, 255, 0.5);
  outline-offset: 2px;
}
</style>

