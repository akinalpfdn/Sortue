# Sortue API Documentation

## Overview

This document provides comprehensive API documentation for Sortue's core components, including data models, view models, utilities, and key interfaces.

## Table of Contents

- [Core Data Models](#core-data-models)
- [Game View Model](#game-view-model)
- [Audio Manager](#audio-manager)
- [Rate Manager](#rate-manager)
- [Color Utilities](#color-utilities)
- [Seeded Generator](#seeded-generator)

---

## Core Data Models

### RGBData

Represents color data with mathematical precision for color interpolation and distance calculations.

```swift
struct RGBData: Equatable, Codable
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `r` | `Double` | Red component value (0.0 - 1.0) |
| `g` | `Double` | Green component value (0.0 - 1.0) |
| `b` | `Double` | Blue component value (0.0 - 1.0) |
| `color` | `Color` | SwiftUI Color representation (computed) |

#### Initializers

```swift
init(r: Double, g: Double, b: Double)
```

Creates a new RGBData instance with the specified RGB values.

#### Static Methods

##### `fromHSB(h:s:b:)`

```swift
static func fromHSB(h: Double, s: Double, b: Double) -> RGBData
```

Creates RGBData from HSB (Hue, Saturation, Brightness) values using UIColor conversion.

**Parameters:**
- `h`: Hue value (0.0 - 1.0)
- `s`: Saturation value (0.0 - 1.0)
- `b`: Brightness value (0.0 - 1.0)

**Returns:** RGBData instance with equivalent RGB values

##### `interpolated(x:y:width:height:corners:)`

```swift
static func interpolated(x: Int, y: Int, width: Int, height: Int, corners: (tl: RGBData, tr: RGBData, bl: RGBData, br: RGBData)) -> RGBData
```

Performs bilinear interpolation to calculate color at a specific grid position.

**Parameters:**
- `x`: Grid X coordinate
- `y`: Grid Y coordinate
- `width`: Grid width
- `height`: Grid height
- `corners`: Tuple of four corner colors

**Returns:** Interpolated RGBData at the specified position

#### Instance Methods

##### `distance(to:)`

```swift
func distance(to other: RGBData) -> Double
```

Calculates Euclidean distance between two colors in RGB space.

**Parameters:**
- `other`: Another RGBData instance

**Returns:** Distance value (0.0 - √3)

##### `isSimilar(to:)`

```swift
func isSimilar(to other: RGBData) -> Bool
```

Determines if two colors are similar within a predefined threshold (0.05 per component).

**Parameters:**
- `other`: Another RGBData instance

**Returns:** `true` if colors are similar, `false` otherwise

---

### Tile

Represents a single tile in the game grid.

```swift
struct Tile: Identifiable, Equatable, Codable
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `Int` | Unique identifier for the tile |
| `correctId` | `Int` | Grid index where the tile should be positioned |
| `rgb` | `RGBData` | Color data for the tile |
| `isFixed` | `Bool` | Whether tile is anchored (corner tiles) |
| `currentIdx` | `Int` | Current grid position (logic helper) |

#### Initializers

```swift
init(id: Int, correctId: Int, rgb: RGBData, isFixed: Bool, currentIdx: Int)
```

Creates a new tile with the specified properties.

---

### GameStatus

Enumeration representing the current state of the game.

```swift
enum GameStatus: String, Codable
```

#### Cases

| Case | Raw Value | Description |
|------|-----------|-------------|
| `preview` | `"preview"` | Game is showing initial color pattern |
| `playing` | `"playing"` | Player can interact with tiles |
| `animating` | `"animating"` | Victory animation in progress |
| `won` | `"won"` | Game completed successfully |
| `gameOver` | `"gameOver"` | Game failed (Precision mode limit exceeded) |

---

### GameMode

Enumeration representing different gameplay modes.

```swift
enum GameMode: String, CaseIterable, Codable
```

#### Cases

| Case | Raw Value | Description |
|------|-----------|-------------|
| `casual` | `"casual"` | Relaxed puzzle experience with hints |
| `precision` | `"precision"` | Strategic gameplay with move limits |
| `pure` | `"pure"` | Ultimate challenge without assistance |

#### Computed Properties

##### `name`

```swift
var name: String
```

Returns the capitalized display name of the game mode.

---

## Game View Model

The central game controller managing state, logic, and user interactions.

```swift
class GameViewModel: ObservableObject
```

### Published Properties

| Property | Type | Description |
|----------|------|-------------|
| `tiles` | `[Tile]` | Current tile arrangement |
| `status` | `GameStatus` | Current game state |
| `gridDimension` | `Int` | Current grid size (NxN) |
| `moves` | `Int` | Number of moves made |
| `selectedTileId` | `Int?` | Currently selected tile ID |
| `currentLevel` | `Int` | Current level number |
| `gameMode` | `GameMode` | Active game mode |
| `minMoves` | `Int` | Minimum moves required to solve |
| `moveLimit` | `Int` | Move limit for Precision mode |
| `timeElapsed` | `TimeInterval` | Time since game start (seconds) |
| `bestTime` | `TimeInterval?` | Best completion time (Casual mode) |
| `bestMoves` | `Int?` | Best move count (Casual mode) |

### Computed Properties

##### `gridSize`

```swift
var gridSize: (w: Int, h: Int)
```

Returns tuple representing grid dimensions.

### Methods

#### Game Management

##### `startNewGame(dimension:preserveColors:)`

```swift
func startNewGame(dimension: Int? = nil, preserveColors: Bool = false)
```

Initializes a new game session.

**Parameters:**
- `dimension`: Optional grid size (defaults to current dimension)
- `preserveColors`: Whether to reuse current color scheme

**Behavior:**
- Generates harmonious corner colors
- Creates interpolated grid
- Schedules automatic shuffle after 2.5 seconds
- Updates level progression
- Resets move counter and timer

##### `selectTile(_:)`

```swift
func selectTile(_ tile: Tile)
```

Handles tile selection logic.

**Parameters:**
- `tile`: The tile to select

**Behavior:**
- Deselects if same tile is tapped
- Swaps if different tile is already selected
- Respects fixed tile restrictions
- Only works during `playing` status

##### `swapTiles(id1:id2:)`

```swift
func swapTiles(id1: Int, id2: Int)
```

Swaps two tiles in the grid.

**Parameters:**
- `id1`: First tile ID
- `id2`: Second tile ID

**Behavior:**
- Animates tile movement
- Increments move counter
- Checks win condition
- Enforces move limits in Precision mode
- Saves game state

##### `useHint()`

```swift
func useHint()
```

Provides assistance by moving one incorrect tile to its correct position.

**Penalties:**
- +5 moves
- +30 seconds to timer

**Restrictions:**
- Only available in Casual mode
- Only works during `playing` status

#### State Management

##### `loadGameState(for:) -> Bool`

```swift
@discardableResult
func loadGameState(for mode: GameMode) -> Bool
```

Loads saved game state for specified mode.

**Parameters:**
- `mode`: Game mode to load

**Returns:** `true` if state loaded successfully, `false` otherwise

**Behavior:**
- Decodes JSON game state
- Restores timer if in playing status
- Loads best statistics
- Handles legacy save migration

##### `clearGameState()`

```swift
func clearGameState()
```

Removes saved game state for current mode and clears legacy saves.

---

## Audio Manager

Manages background music playback and user preferences.

```swift
class AudioManager: ObservableObject
```

### Singleton

```swift
static let shared = AudioManager()
```

### Published Properties

| Property | Type | Description |
|----------|------|-------------|
| `isMusicEnabled` | `Bool` | Whether background music should play |

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `audioPlayer` | `AVAudioPlayer?` | Audio player instance |

### Methods

##### `playBackgroundMusic()`

```swift
func playBackgroundMusic()
```

Starts or resumes background music playback.

**Behavior:**
- Respects `isMusicEnabled` setting
- Configures audio session for ambient mixing
- Loops music indefinitely
- Uses 70% volume

##### `pauseBackgroundMusic()`

```swift
func pauseBackgroundMusic()
```

Pauses current music playback without resetting position.

##### `stopBackgroundMusic()`

```swift
func stopBackgroundMusic()
```

Stops music playback and resets to beginning.

---

## Rate Manager

Manages app rating prompts and user feedback collection.

```swift
class RateManager: ObservableObject
```

### Singleton

```swift
static let shared = RateManager()
```

### Published Properties

| Property | Type | Description |
|----------|------|-------------|
| `showRatePopup` | `Bool` | Whether to display rating prompt |

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `currentLaunchCount` | `Int` | Total app launches |

### Methods

##### `appDidLaunch()`

```swift
func appDidLaunch()
```

Called when app launches. Increments launch counter and determines if rating prompt should be shown.

##### `rateNow()`

```swift
func rateNow()
```

Opens App Store for rating and disables future prompts.

##### `remindMeLater()`

```swift
func remindMeLater()
```

Delays rating prompt for 10 additional launches.

---

## Color Utilities

Provides color interpolation and gradient generation functionality.

### Static Methods

#### `interpolateColor(x:y:width:height:corners:)`

```swift
static func interpolateColor(x: Int, y: Int, width: Int, height: Int, corners: (tl: RGBData, tr: RGBData, bl: RGBData, br: RGBData)) -> RGBData
```

Performs bilinear interpolation for gradient color calculation.

**Parameters:**
- `x`, `y`: Grid coordinates
- `width`, `height`: Grid dimensions
- `corners`: Four corner anchor colors

**Returns:** Interpolated color at specified position

**Algorithm:**
1. Calculate horizontal interpolation for top and bottom edges
2. Interpolate vertically between edge results
3. Return final color value

---

## Seeded Generator

Provides deterministic random number generation for reproducible puzzles.

```swift
struct SeededGenerator: RandomNumberGenerator
```

### Initializer

```swift
init(seed: UInt64)
```

Creates generator with specified seed value.

### Methods

#### `next() -> UInt64`

Generates next random number in sequence using XOR-shift algorithm.

#### `next<T>(upperBound:) -> T`

Generates random value less than specified upper bound.

**Parameters:**
- `upperBound`: Maximum exclusive value

**Returns:** Random value of appropriate type

---

## Usage Examples

### Starting a New Game

```swift
let viewModel = GameViewModel()

// Start casual game with 6x6 grid
viewModel.gameMode = .casual
viewModel.startNewGame(dimension: 6)

// Start precision game (auto-scales based on level)
viewModel.gameMode = .precision
viewModel.startNewGame()
```

### Handling Tile Selection

```swift
func handleTileTap(_ tile: Tile) {
    guard viewModel.status == .playing else { return }
    viewModel.selectTile(tile)
}
```

### Using Audio Manager

```swift
// Configure audio
AudioManager.shared.isMusicEnabled = true

// Play background music
AudioManager.shared.playBackgroundMusic()

// Pause when app backgrounds
AudioManager.shared.pauseBackgroundMusic()
```

### Saving Custom Game State

```swift
// Game automatically saves after each move
// Manual save if needed:
viewModel.saveGameState()
```

---

## Error Handling

### Common Error Scenarios

1. **Missing Audio File**: Gracefully handled with console logging
2. **Save State Corruption**: Creates new game if load fails
3. **Invalid Tile Selection**: Safely ignored with early returns
4. **Memory Pressure**: Automatic cleanup of audio and timer resources

### Debug Logging

The app uses console logging for debugging purposes:
- Audio file loading issues
- Game state save/load failures
- Invalid user interactions

---

## Performance Considerations

### Optimization Techniques

1. **Lazy Grid Loading**: Tiles created on-demand
2. **Efficient Animation**: Hardware-accelerated transitions
3. **Memory Management**: Proper cleanup of AVAudioPlayer and Task objects
4. **Minimal JSON Payload**: Compact game state encoding
5. **Cached Interpolations**: Pre-computed color values

### Memory Footprint

- Tile objects: ~64 bytes each
- Game state: ~2KB for 12x12 grid
- Audio buffer: ~5MB for background music

---

This API documentation provides comprehensive coverage of Sortue's core components and their usage patterns. For implementation details, refer to the source code comments and the main README.md file.