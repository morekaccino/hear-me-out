# Firestore Service Usage Guide

This document explains how to use the Firestore services in the application.

## Architecture

The Firestore service layer follows SOLID principles with a base service class and specialized service classes for different collections.

### Base Service: `FirestoreService`

Provides CRUD operations for any Firestore collection.

```javascript
import { FirestoreService } from '@/shared/services/firestore/FirestoreService'

const notesService = new FirestoreService('notes')
```

### User Service: `UserService`

Specialized service for managing user documents in the `users` collection.

```javascript
import { userService } from '@/shared/services/firestore/UserService'

// Initialize user (creates document if doesn't exist)
await userService.initializeUser(userId)

// Get user profile
const profile = await userService.getUserProfile(userId)

// Update user profile
await userService.updateUserProfile(userId, {
  displayName: 'John Doe',
  level: 5
})
```

## Creating New Services

To create a service for a new collection:

```javascript
import { FirestoreService } from './FirestoreService'

export class ProgressService extends FirestoreService {
  constructor() {
    super('progress') // collection name
  }

  async saveProgress(userId, noteData) {
    return this.createDocument(userId, {
      notes: noteData,
      completedAt: new Date()
    })
  }
}

export const progressService = new ProgressService()
```

## Available Methods

### FirestoreService (Base)

- `createDocument(docId, data, merge = true)` - Create or update a document
- `getDocument(docId)` - Get a document by ID
- `updateDocument(docId, data)` - Update existing document
- `documentExists(docId)` - Check if document exists

### UserService (Extends FirestoreService)

- `initializeUser(userId)` - Create user document if not exists
- `getUserProfile(userId)` - Get user profile data
- `updateUserProfile(userId, profileData)` - Update user profile

## Automatic Timestamps

All documents automatically include:
- `updated_at` - Server timestamp added/updated on create and update operations

User documents additionally include:
- `account_created` - Server timestamp when user is first created

## Example: Complete User Flow

```javascript
import { useAuth } from '@/shared/composables/useAuth'
import { userService } from '@/shared/services/firestore/UserService'

// On login
const { user, initAuth } = useAuth()
const authenticatedUser = await initAuth()

// Initialize user document
await userService.initializeUser(authenticatedUser.uid)

// Later: Update user data
await userService.updateUserProfile(authenticatedUser.uid, {
  notesCompleted: 10,
  currentLevel: 3
})

// Get user data
const profile = await userService.getUserProfile(authenticatedUser.uid)
console.log(profile)
```

