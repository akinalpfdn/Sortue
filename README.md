# Sortue - Color Grid Puzzle Game

A beautifully designed iOS color sorting puzzle game built with SwiftUI. Sortue challenges players to rearrange scrambled color gradients back to their original harmonious state.

![Sortue App Icon](Sortue/Assets.xcassets/AppIcon.appiconset/AppIcon~ios-marketing.png)

## 🎮 Game Overview

Sortue is a sophisticated color puzzle game where players interact with gradient grids that have been scrambled. The objective is to restore the color harmony by swapping tiles until each color is in its correct position.

### Game Modes

- **Casual Mode**: Relaxing puzzle experience with customizable grid sizes (4x4 to 12x12)
- **Precision Mode**: Strategic gameplay with move limits and progressively challenging levels
- **Pure Mode**: Ultimate challenge with no hints, time pressure, or assistance features

### Key Features

- 🎨 **Curated Color Palettes**: Seven harmonious color themes (Sunset, Ocean, Forest, Berry, Aurora, Citrus, Midnight)
- 🧩 **Progressive Difficulty**: Dynamic grid sizing based on skill level and game mode
- 🏆 **Performance Tracking**: Best time and move tracking for casual mode
- 💾 **Game State Persistence**: Save and resume progress across sessions
- 🔊 **Ambient Audio**: Background music with user controls
- ⭐ **Rating System**: App store rating prompts with intelligent timing
- 🎯 **Hint System**: Strategic hints with move and time penalties (Casual mode only)

## 🏗️ Architecture

### Project Structure

```
Sortue/
├── SortueApp.swift              # App entry point and configuration
├── ContentView.swift            # Main app navigation and state management
├── Models/
│   └── GameModels.swift         # Core data structures (Tile, GameStatus, GameMode, RGBData)
├── ViewModels/
│   └── GameViewModel.swift      # Game logic, state management, and business rules
├── Views/
│   ├── GameView.swift           # Main game interface
│   ├── LandingView.swift        # App introduction screen
│   ├── ModeSelectionView.swift  # Game mode selection
│   ├── Components/
│   │   └── WheelPicker.swift    # Grid size selector component
│   └── Overlays/                # Modal screens
│       ├── AboutOverlay.swift
│       ├── SettingsOverlay.swift
│       ├── RateOverlay.swift
│       ├── WinOverlay.swift
│       ├── GameOverOverlay.swift
│       └── SolutionOverlay.swift
└── Utilities/
    ├── AudioManager.swift       # Background music management
    ├── Color.swift             # Color interpolation utilities
    ├── Font+App.swift          # Custom font extensions
    ├── NavigationFix.swift     # Navigation gesture handling
    ├── RateManager.swift       # App rating logic
    ├── SeededGenerator.swift   # Deterministic random number generation
    └── WinMessages.swift       # Victory message collection
```

### Core Components

#### Data Models

- **RGBData**: Precise color representation with interpolation and distance calculations
- **Tile**: Individual puzzle tiles with position, color, and state information
- **GameStatus**: Game state enumeration (preview, playing, animating, won, gameOver)
- **GameMode**: Three distinct gameplay modes with unique rulesets

#### Game Logic (GameViewModel)

The `GameViewModel` class serves as the central game controller, implementing:

- Grid generation with bilinear color interpolation
- Tile shuffling with cycle-based minimum move calculation
- Game state persistence using JSON encoding/decoding
- Timer management and move tracking
- Win condition detection and level progression
- Multi-modal save state management

#### Color System

Sortue uses a sophisticated color generation system:

- **Harmony Profiles**: Seven curated color palettes ensuring aesthetic consistency
- **Bilinear Interpolation**: Smooth color gradients across the grid
- **Seed-based Generation**: Deterministic color schemes for competitive modes
- **Distance Calculations**: Mathematical color similarity detection

## 🎯 Gameplay Mechanics

### Grid Generation

1. **Corner Colors**: Four harmonious colors are selected based on the chosen palette
2. **Gradient Creation**: Bilinear interpolation creates smooth color transitions
3. **Tile Assignment**: Each position receives a unique color value
4. **Corner Anchoring**: Corner tiles are fixed to provide visual reference points

### Shuffling Algorithm

The game employs a sophisticated shuffling system:

- **Cycle Detection**: Calculates minimum moves required for solution
- **Preserved Anchors**: Corner tiles remain fixed for visual orientation
- **Deterministic Randomness**: Seeded generation ensures reproducible puzzles

### Win Conditions

Players win by arranging all tiles in their correct positions. The system verifies victory by checking that each tile's current position matches its intended correct position.

## 📱 User Interface

### SwiftUI Architecture

The app follows modern SwiftUI patterns:

- **MVVM Pattern**: Clear separation between views and view models
- **State Management**: Combine framework for reactive updates
- **Animation System**: Smooth transitions using SwiftUI's animation system
- **Navigation**: NavigationStack for iOS 16+ navigation patterns

### Accessibility

- VoiceOver support for visually impaired users
- Dynamic type sizing for text
- High contrast color schemes
- Haptic feedback for game interactions

## 🔧 Technical Implementation

### Dependencies

- **SwiftUI**: Modern declarative UI framework
- **Combine**: Reactive programming for state management
- **AVFoundation**: Audio playback functionality
- **UserDefaults**: Persistent settings and game state storage

### Performance Optimizations

- **Lazy Loading**: On-demand view creation
- **Efficient Animations**: Hardware-accelerated transitions
- **Memory Management**: Proper cleanup of audio and timer resources
- **State Persistence**: Minimal JSON encoding for fast save/load operations

### Code Quality

- **SOLID Principles**: Clean, maintainable architecture
- **Type Safety**: Strong typing with Swift's type system
- **Error Handling**: Graceful degradation for edge cases
- **Documentation**: Comprehensive inline documentation

## 🎨 Design System

### Color Theory

The game's color system is based on established color harmony principles:

- **Complementary Colors**: Opposite colors on the color wheel for contrast
- **Analogous Colors**: Adjacent colors for smooth transitions
- **Triadic Colors**: Evenly spaced colors for balanced palettes

### User Experience

- **Intuitive Controls**: Simple tap-to-select, tap-to-swap mechanics
- **Visual Feedback**: Clear selection indicators and smooth animations
- **Progressive Disclosure**: Features revealed as needed
- **Forgiving Design**: No time pressure in casual mode

## 📊 Game Analytics

### Tracked Metrics

- **Best Times**: Fastest completion times per grid size (Casual mode)
- **Best Moves**: Minimum moves achieved per grid size (Casual mode)
- **Level Progression**: Current level and completion status
- **Play Patterns**: Session duration and frequency

### Performance Indicators

- **Move Efficiency**: Comparison to minimum possible moves
- **Time Performance**: Completion time relative to best
- **Skill Progression**: Difficulty advancement tracking

## 🔮 Future Enhancements

### Planned Features

- **Multiplayer Support**: Competitive puzzle solving
- **Daily Challenges**: Time-limited special puzzles
- **Custom Palettes**: User-created color schemes
- **Achievement System**: Badges and milestones
- **Leaderboards**: Global and friend comparisons

### Technical Improvements

- **Cloud Sync**: Cross-device progress synchronization
- **Advanced Analytics**: Detailed gameplay insights
- **Performance Monitoring**: Crash reporting and optimization
- **Localization**: Multi-language support

## 🛠️ Development

### Build Requirements

- **Xcode 15.0+**
- **iOS 16.0+**
- **Swift 5.9+**

### Development Setup

1. Clone the repository
2. Open `Sortue.xcodeproj` in Xcode
3. Ensure development team is configured for signing
4. Build and run on simulator or device

### Code Style

The project follows Swift style guidelines:

- **Naming**: Descriptive, camelCase for variables, PascalCase for types
- **Documentation**: Comprehensive inline documentation
- **Organization**: Logical file grouping and naming
- **Testing**: Unit tests for game logic and utilities

## 📄 License

This project is proprietary software. All rights reserved.

## 🤝 Contributing

This is a private project. Contributions are not accepted at this time.

---

*Sortue - Where color meets challenge, and harmony emerges from chaos.*