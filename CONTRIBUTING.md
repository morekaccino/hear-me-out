# 🤝 Contributing to Hear Me Out

First off, **thank you** for considering contributing! It's people like you that make Hear Me Out such a great tool for musicians worldwide. 🎵

## 🌟 How Can I Contribute?

### 🐛 Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

**Bug Report Template:**
```markdown
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce:
1. Go to '...'
2. Click on '...'
3. Play note '...'
4. See error

**Expected behavior**
What you expected to happen.

**Screenshots**
If applicable, add screenshots.

**Environment:**
 - OS: [e.g. Windows 11, macOS 14]
 - Browser: [e.g. Chrome 120, Firefox 121]
 - Version: [e.g. 1.0.0]
 - Instrument: [e.g. Acoustic Guitar]

**Additional context**
Any other context about the problem.
```

### 💡 Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- **Use a clear, descriptive title**
- **Provide detailed description** of the suggested enhancement
- **Explain why this enhancement would be useful** to most users
- **List examples** of other apps where this feature exists (if applicable)

### 🎨 Pull Requests

The process:

1. **Fork the repo** and create your branch from `main`
2. **Make your changes** following our code style
3. **Test your changes** thoroughly
4. **Update documentation** if needed
5. **Write clear commit messages**
6. **Submit a pull request**

## 🏗️ Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/hear-me-out.git
cd hear-me-out

# Install dependencies
npm install

# Start dev server
npm run dev

# Open http://localhost:5173
```

## 📏 Code Style Guidelines

### Vue Components

```vue
<script setup>
// ✅ DO: Use Composition API with script setup
import { ref, computed, onMounted } from 'vue'

const count = ref(0)
const doubled = computed(() => count.value * 2)

onMounted(() => {
  console.log('Component mounted')
})
</script>

<template>
  <!-- ✅ DO: Use semantic HTML -->
  <section class="card">
    <h2>{{ title }}</h2>
    <p>{{ description }}</p>
  </section>
</template>

<style scoped>
/* ✅ DO: Use scoped styles */
.card {
  /* Use CSS custom properties from variables.css */
  background: var(--card-bg);
  border-radius: var(--border-radius);
}
</style>
```

### Services (Business Logic)

```javascript
// ✅ DO: Keep business logic in services, not components
export class MyService {
  constructor() {
    this.state = []
  }

  // ✅ DO: Use clear, descriptive method names
  addItem(item) {
    this.state.push(item)
    return this.state
  }

  // ✅ DO: Implement serialization for Firestore persistence
  serializeState() {
    return {
      state: this.state,
      timestamp: Date.now()
    }
  }

  // ✅ DO: Restore from plain objects
  _restoreState(data) {
    this.state = data.state || []
  }
}
```

### Composables (Vue Integration)

```javascript
// ✅ DO: Use composables to bridge services and Vue
import { ref, computed } from 'vue'

export function useMyFeature() {
  const service = new MyService()
  const items = ref([])

  async function addItem(item) {
    const result = await service.addItem(item)
    items.value = result
  }

  return {
    items: computed(() => items.value),
    addItem
  }
}
```

### Naming Conventions

- **Components**: PascalCase (`NoteCard.vue`, `CardStack.vue`)
- **Composables**: camelCase with `use` prefix (`usePitchDetection.js`)
- **Services**: PascalCase with `Service` suffix (`PitchDetectionService.js`)
- **Constants**: SCREAMING_SNAKE_CASE (`MAX_CARDS`, `MIN_CLARITY`)
- **Variables**: camelCase (`noteValue`, `isDetecting`)

## 🧪 Testing

Currently, we have basic tests for the Leitner system:

```bash
# Run tests (when available)
npm test
```

**We'd love help adding more tests!** Priority areas:
- Pitch detection accuracy
- Learning algorithm edge cases
- Firebase integration
- UI component behavior

## 📝 Commit Message Guidelines

We follow conventional commits for clarity:

```bash
# Format: <type>(<scope>): <subject>

feat(pitch): add support for custom A4 tuning
fix(cards): resolve swipe animation glitch on mobile
docs(readme): update installation instructions
style(ui): improve card shadow depth
refactor(service): extract common Firestore logic
perf(audio): optimize FFT buffer size
test(leitner): add edge case for box promotion
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Formatting (no code change)
- `refactor`: Code restructuring
- `perf`: Performance improvement
- `test`: Adding tests
- `chore`: Maintenance tasks

## 🎯 Project Architecture

Before making changes, understand our architecture:

```
Service Layer (Business Logic)
    ↓
Composables (Vue + Firebase Integration)
    ↓
Components (UI Only)
```

**Key Principles:**
1. **Services** contain stateful business logic
2. **Composables** orchestrate services with Vue reactivity
3. **Components** are presentational and emit events
4. **Firestore operations** extend `FirestoreService` base class
5. **All state changes** auto-save with 500ms debounce

See [copilot-instructions.md](.github/copilot-instructions.md) for detailed architecture docs.

## 🚀 Feature Requests

When proposing major features:

1. **Open an issue first** to discuss the approach
2. **Wait for maintainer feedback** before starting work
3. **Break large features** into smaller PRs
4. **Include documentation** and examples

**Current roadmap items we'd love help with:**
- 🎹 Piano keyboard visualization mode
- 📊 Advanced statistics dashboard
- 🌍 Multi-language support
- 🎵 Multiple note/chord detection
- 📱 Native mobile app (React Native/Flutter)
- 🎮 Gamification (achievements, leaderboards)

## ❓ Questions?

- 💬 Open a [GitHub Discussion](https://github.com/morekaccino/hear-me-out/discussions)
- 🐛 File an [Issue](https://github.com/morekaccino/hear-me-out/issues)
- 📧 Contact the maintainer

## 🎉 Recognition

Contributors will be:
- Listed in our README
- Credited in release notes
- Given our eternal gratitude! 💜

---

<div align="center">

**Thank you for making Hear Me Out better!** 🎸🎹🎤

*Happy coding, and keep making music!* 🎵

</div>
