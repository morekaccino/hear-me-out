<script setup>
import { onMounted } from 'vue'
import { SwipeTrainer } from '../features/swipe-trainer'
import { useAuth } from '../shared/composables/useAuth'
import { userService } from '../shared/services/firestore/UserService'

const { initAuth } = useAuth()

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


