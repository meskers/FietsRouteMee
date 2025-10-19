# Performance Fixes - App Vastlopen Oplossen

## Problemen Geïdentificeerd:

1. **Polling Loops** - SearchView en AdvancedRoutePlanner gebruiken while loops die de UI blokkeren
2. **Memory Leaks** - Meerdere AppSettingsManager instances per view
3. **Main Thread Blocking** - CoreData en route calculations op main thread
4. **Excessive Updates** - MapView updates te vaak

## Oplossingen:

### 1. Vervang Polling met Combine Publishers
- Gebruik `@Published` properties met `.sink()` in plaats van while loops
- Async/await met proper task cancellation

### 2. Singleton Pattern voor Managers
- AppSettingsManager als shared instance
- Voorkom multiple instances

### 3. Background Queue voor Heavy Operations
- CoreData saves op background context
- Route calculations blijven async maar met debouncing

### 4. Optimize MapView Updates
- Debounce region updates
- Batch route updates

