import SwiftUI
import Combine

class GameViewModel: ObservableObject {
    @Published var tiles: [Tile] = []
    @Published var status: GameStatus = .preview
    @Published var gridDimension: Int = 4
    @Published var moves: Int = 0
    @Published var selectedTileId: Int? = nil
    
    @Published var currentLevel: Int = 1
    @Published var gameMode: GameMode = .casual

    @Published var minMoves: Int = 0
    @Published var moveLimit: Int = 0 // For Precision mode
    @Published var timeElapsed: TimeInterval = 0
    @Published var bestTime: TimeInterval? = nil
    @Published var bestMoves: Int? = nil
    
    private var shuffleTask: Task<Void, Never>?
    private var winTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?
    
    private var currentCorners: (tl: RGBData, tr: RGBData, bl: RGBData, br: RGBData)?
    
    var gridSize: (w: Int, h: Int) { (gridDimension, gridDimension) }
    
    init() {
        loadGameState()
        if tiles.isEmpty {
            startNewGame()
        }
    }
    
    func startNewGame(dimension: Int? = nil, preserveColors: Bool = false) {
        if let d = dimension { self.gridDimension = d }

        // Update level for the current dimension or mode
        let levelKey: String
        switch gameMode {
        case .casual:
            levelKey = "level_count_\(gridDimension)"
            loadBestStats() // Refresh stats for new dimension
        case .precision:
            levelKey = "level_count_LADDER"
        case .pure:
            levelKey = "level_count_CHALLENGE"
        }
        self.currentLevel = UserDefaults.standard.integer(forKey: levelKey) + 1

        // Clear saved game state when starting a new game (unless we want to persist mode?)
        // Ideally we should save the mode too.
        
        clearGameState()
        
        shuffleTask?.cancel()
        winTask?.cancel()
        stopTimer()
        
        status = .preview
        moves = 0
        timeElapsed = 0
        minMoves = 0
        moveLimit = 0
        selectedTileId = nil

        // Dynamic Grid Sizing for Precision/Pure
        if gameMode == .precision || gameMode == .pure {
            let targetDim: Int
            if currentLevel <= 15 {
                targetDim = 4
            } else {
                // Starts at 5 for lvl 16. Increases every 7 levels.
                targetDim = min(12, 5 + (currentLevel - 16) / 7)
            }
            
            if gridDimension != targetDim {
                gridDimension = targetDim
                self.gridDimension = targetDim // Update published prop
            }
        }
        
        // Refresh dimensions
        let (w, h) = (gridDimension, gridDimension)
        
        // 1. Generate corners
        let corners: (tl: RGBData, tr: RGBData, bl: RGBData, br: RGBData)
        
        if preserveColors, let current = currentCorners {
            corners = current
        } else {
            // Use Curated Strategy
            let seed: UInt64?
            if gameMode == .casual {
                seed = nil
            } else {
                // Unique seed per mode
                // Pure mode gets a bitflip mask to be different from Precision
                let modeMask: UInt64 = (gameMode == .pure) ? 0x5555_5555_5555_5555 : 0
                seed = UInt64(currentLevel) ^ modeMask
            }
            corners = generateHarmoniousCorners(seed: seed)
            currentCorners = corners
        }
        
        var newTiles: [Tile] = []
        var idCounter = 0
        
        // 2. Generate Grid
        for y in 0..<h {
            for x in 0..<w {
                // EXPLICIT Corner Logic to avoid "edges" becoming fixed
                let isTopLeft = (x == 0 && y == 0)
                let isTopRight = (x == w - 1 && y == 0)
                let isBottomLeft = (x == 0 && y == h - 1)
                let isBottomRight = (x == w - 1 && y == h - 1)
                
                let isFixed = isTopLeft || isTopRight || isBottomLeft || isBottomRight
                
                let colorData = RGBData.interpolated(x: x, y: y, width: w, height: h, corners: corners)
                
                newTiles.append(Tile(
                    id: idCounter,
                    correctId: idCounter,
                    rgb: colorData,
                    isFixed: isFixed,
                    currentIdx: idCounter
                ))
                idCounter += 1
            }
        }
        
        self.tiles = newTiles
        
        // 3. Schedule Shuffle
        // 3. Schedule Shuffle
        let shuffleSeed: UInt64?
        if gameMode == .casual {
            shuffleSeed = nil
        } else {
            let modeMask: UInt64 = (gameMode == .pure) ? 0x5555_5555_5555_5555 : 0
            shuffleSeed = UInt64(currentLevel) ^ modeMask
        }
        
        shuffleTask = Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000) // 2.5s
            if !Task.isCancelled {
                await MainActor.run { self.shuffleBoard(seed: shuffleSeed) }
            }
        }
    }
    
    private func shuffleBoard(seed: UInt64? = nil) {
        var mutableTiles = tiles.filter { !$0.isFixed }
        let fixedTiles = tiles.filter { $0.isFixed }
        
        if let seed = seed {
            var rng = SeededGenerator(seed: seed)
            mutableTiles.shuffle(using: &rng)
        } else {
            mutableTiles.shuffle()
        }
        
        var finalGrid = Array(repeating: Tile?.none, count: gridDimension * gridDimension)
        
        for tile in fixedTiles {
            finalGrid[tile.correctId] = tile
        }
        
        var mutIdx = 0
        for i in 0..<finalGrid.count {
            if finalGrid[i] == nil {
                // We need to update currentIdx because the Tile is moving to a new slot 'i'
                // But Tile struct is immutable let. We need to create copies or handle it properly.
                // In Swift struct, we create a new instance with updated property.
                var tile = mutableTiles[mutIdx]
                tile.currentIdx = i
                finalGrid[i] = tile
                mutIdx += 1
            }
        }
        
        let shuffled = finalGrid.compactMap { $0 }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            self.tiles = shuffled
            self.status = .playing
        }
        
        startTimer()
        
        // Calculate Min Moves
        let minM = calculateMinMoves(tiles: shuffled)
        self.minMoves = minM
        
        // Calculate Move Limit (Precision)
        if gameMode == .precision {
            switch gridDimension {
            case 4...7:
                moveLimit = Int(1.6 * Double(minM)) + 4
            case 8...11:
                moveLimit = Int(2.2 * Double(minM)) + 8
            default:
                moveLimit = Int(2.5 * Double(minM)) + 12
            }
        } else {
            moveLimit = 0
        }
        
        saveGameState()
    }

    private func calculateMinMoves(tiles: [Tile]) -> Int {
        var visited = [Bool](repeating: false, count: tiles.count)
        var cycles = 0
        
        for i in 0..<tiles.count {
            if visited[i] { continue }
            
            // If at correct position, 1-cycle
            if tiles[i].correctId == i {
                visited[i] = true
                cycles += 1
                continue
            }
            
            var current = i
            while !visited[current] {
                visited[current] = true
                let targetPos = tiles[current].correctId
                current = targetPos
            }
            cycles += 1
        }
        
        return tiles.count - cycles
    }
    
    // Generates aesthetically pleasing palettes using Curated Harmony Profiles
    private func generateHarmoniousCorners(seed: UInt64? = nil) -> (tl: RGBData, tr: RGBData, bl: RGBData, br: RGBData) {
        
        // Setup RNG
        var rng: RandomNumberGenerator
        if let seed = seed {
            rng = SeededGenerator(seed: seed)
        } else {
            rng = SystemRandomNumberGenerator()
        }
        
        // We define specific "Vibes" that are guaranteed to look good.
        // No more random "Green + Brown" accidents.
        enum HarmonyProfile: CaseIterable {
            case sunset      // Pinks, Oranges, Purples, Warm Yellows
            case ocean       // Deep Blues, Aquas, Teals, White
            case forest      // Emeralds, Limes, Teals (Explicitly avoids brown)
            case berry       // Magentas, Violets, Deep Reds
            case aurora      // Greens, Blues, Purples (Northern Lights style)
            case citrus      // Lemons, Limes, Oranges (Bright & Zesty)
            case midnight    // Deep Blues, Purples, Dark Greys
        }
        
        let profile = HarmonyProfile.allCases.randomElement(using: &rng)!
        
        // Helper to randomize slightly within a safe range
        func rnd(_ range: ClosedRange<Double>) -> Double { Double.random(in: range, using: &rng) }
        
        var h1, s1, b1: Double
        var h2, s2, b2: Double
        var h3, s3, b3: Double
        var h4, s4, b4: Double
        
        switch profile {
        case .sunset:
            // Warm gradient: Yellow/Orange -> Purple/Pink
            h1 = rnd(0.12...0.16) // Warm Yellow
            s1 = rnd(0.2...0.4); b1 = rnd(0.95...1.0) // Light
            
            h2 = rnd(0.02...0.08) // Orange/Red
            s2 = rnd(0.7...0.9); b2 = rnd(0.9...1.0)
            
            h3 = rnd(0.85...0.92) // Magenta
            s3 = rnd(0.4...0.6); b3 = rnd(0.8...0.9)
            
            h4 = rnd(0.75...0.82) // Deep Purple
            s4 = rnd(0.8...1.0); b4 = rnd(0.3...0.5) // Dark
            
        case .ocean:
            // Cool gradient: White/Cyan -> Deep Navy
            h1 = rnd(0.5...0.55) // Cyan
            s1 = rnd(0.05...0.2); b1 = rnd(0.95...1.0) // Almost white
            
            h2 = rnd(0.55...0.6) // Sky Blue
            s2 = rnd(0.5...0.7); b2 = rnd(0.9...1.0)
            
            h3 = rnd(0.6...0.65) // Azure
            s3 = rnd(0.6...0.8); b3 = rnd(0.6...0.8)
            
            h4 = rnd(0.65...0.7) // Deep Blue
            s4 = rnd(0.9...1.0); b4 = rnd(0.2...0.4) // Dark
            
        case .forest:
            // Fresh greens: Lime -> Emerald -> Teal (No Brown!)
            h1 = rnd(0.25...0.32) // Fresh Green/Lime
            s1 = rnd(0.3...0.5); b1 = rnd(0.9...1.0) // Bright
            
            h2 = rnd(0.35...0.42) // Green
            s2 = rnd(0.6...0.8); b2 = rnd(0.8...0.9)
            
            h3 = rnd(0.45...0.5) // Teal Green
            s3 = rnd(0.5...0.7); b3 = rnd(0.6...0.8)
            
            h4 = rnd(0.5...0.55) // Dark Teal
            s4 = rnd(0.8...1.0); b4 = rnd(0.2...0.4) // Dark
            
        case .berry:
            // Pink -> Red -> Purple
            h1 = rnd(0.9...0.95) // Light Pink
            s1 = rnd(0.2...0.4); b1 = rnd(0.95...1.0)
            
            h2 = rnd(0.95...1.0) // Red/Pink
            s2 = rnd(0.7...0.9); b2 = rnd(0.8...1.0)
            
            h3 = rnd(0.7...0.8) // Violet
            s3 = rnd(0.5...0.7); b3 = rnd(0.6...0.8)
            
            h4 = rnd(0.8...0.9) // Deep Magenta
            s4 = rnd(0.9...1.0); b4 = rnd(0.2...0.4)
        
        case .aurora:
            // Green -> Blue -> Purple (Classic Northern Lights)
            h1 = rnd(0.3...0.35) // Green
            s1 = rnd(0.4...0.6); b1 = rnd(0.9...1.0)
            
            h2 = rnd(0.5...0.55) // Cyan
            s2 = rnd(0.6...0.8); b2 = rnd(0.8...0.9)
            
            h3 = rnd(0.6...0.65) // Blue
            s3 = rnd(0.5...0.7); b3 = rnd(0.6...0.8)
            
            h4 = rnd(0.75...0.8) // Purple
            s4 = rnd(0.8...1.0); b4 = rnd(0.3...0.5)

        case .citrus:
            // Yellow -> Orange -> Lime
            h1 = rnd(0.14...0.18) // Lemon Yellow
            s1 = rnd(0.2...0.4); b1 = rnd(0.95...1.0)
            
            h2 = rnd(0.08...0.12) // Orange Yellow
            s2 = rnd(0.6...0.8); b2 = rnd(0.9...1.0)
            
            h3 = rnd(0.25...0.3) // Lime
            s3 = rnd(0.5...0.7); b3 = rnd(0.7...0.9)
            
            h4 = rnd(0.02...0.06) // Deep Orange
            s4 = rnd(0.9...1.0); b4 = rnd(0.4...0.6)
            
        case .midnight:
            // Grey -> Blue -> Violet
            h1 = rnd(0.6...0.7) // Blue-ish Grey
            s1 = rnd(0.0...0.1); b1 = rnd(0.9...1.0) // White/Grey
            
            h2 = rnd(0.6...0.65) // Slate Blue
            s2 = rnd(0.3...0.5); b2 = rnd(0.6...0.8)
            
            h3 = rnd(0.7...0.75) // Violet Grey
            s3 = rnd(0.4...0.6); b3 = rnd(0.5...0.7)
            
            h4 = rnd(0.65...0.7) // Midnight Blue
            s4 = rnd(0.8...1.0); b4 = rnd(0.1...0.3) // Very Dark
        }
        
        // Define all 4 color objects
        let c1 = RGBData.fromHSB(h: h1, s: s1, b: b1) // Lightest
        let c4 = RGBData.fromHSB(h: h4, s: s4, b: b4) // Darkest
        let c2 = RGBData.fromHSB(h: h2, s: s2, b: b2) // Mid 1
        let c3 = RGBData.fromHSB(h: h3, s: s3, b: b3) // Mid 2

        // Rotate/Shuffle assignments so "Light" isn't always Top-Left
        // We pick a random rotation for the corner assignment
        let rotation = Int.random(in: 0...3, using: &rng)
        
        let tl, tr, bl, br: RGBData
        
        switch rotation {
        case 0: // Original (Light TL -> Dark BR)
            tl = c1; tr = c2; bl = c3; br = c4
        case 1: // Rotated 90 (Light TR -> Dark BL)
            tl = c3; tr = c1; bl = c4; br = c2
        case 2: // Rotated 180 (Light BR -> Dark TL)
            tl = c4; tr = c3; bl = c2; br = c1
        default: // Rotated 270 (Light BL -> Dark TR)
            tl = c2; tr = c4; bl = c1; br = c3
        }
        
        return (tl, tr, bl, br)
    }
    

    // Removed old shuffleBoard that was part of GameViewModel but is now private updated above
    // Wait, the previous shuffleBoard func is below. I should replace IT.
    // I will replace the call site in startNewGame first (done above), and finding the old definition to remove/update.
    // The instructions say "Update startNewGame", "Update shuffleBoard".
    // I have updated startNewGame to use the NEW logic but I pasted `private func shuffleBoard` inside `startNewGame` replacement block?
    // No, I pasted it AFTER startNewGame block?
    // Ah, I see. In the previous replacement block I closed the `startNewGame` function and then defined `private func shuffleBoard`.
    // This effectively duplicated `shuffleBoard` if it existed below or shadowed it.
    // I need to be careful. The original file HAS `private func shuffleBoard` at line 247.
    // My previous replacement replaced lines 88-93 (Task block).
    // So I inserted `private func shuffleBoard` right after `startNewGame`.
    // This is valid Swift, but now I have TWO `shuffleBoard` functions.
    // I MUST REMOVE the old `shuffleBoard` function at line 247.
    
    // Correction: I will use THIS block to remove the old shuffleBoard implementation to avoid duplication errors.
    
    
    func selectTile(_ tile: Tile) {
        guard status == .playing, !tile.isFixed else { return }
        
        if let selectedId = selectedTileId {
            if selectedId == tile.id {
                selectedTileId = nil
            } else {
                swapTiles(id1: selectedId, id2: tile.id)
                selectedTileId = nil
            }
        } else {
            selectedTileId = tile.id
        }
    }
    
    func swapTiles(id1: Int, id2: Int) {
        guard let idx1 = tiles.firstIndex(where: { $0.id == id1 }),
              let idx2 = tiles.firstIndex(where: { $0.id == id2 }) else { return }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            tiles.swapAt(idx1, idx2)
        }
        moves += 1

        // Save game state after each move
        saveGameState()

        checkWinCondition() // Check win first
        
        if status != .won && status != .animating {
            // Check Move Limit for Precision
            if gameMode == .precision && moves >= moveLimit {
                status = .gameOver
                saveGameState()
            }
        }
    }
    
    func useHint() {
        guard status == .playing else { return }

        if let wrongIdx = tiles.firstIndex(where: { $0.correctId != tiles.firstIndex(of: $0) && !$0.isFixed }) {
            let tileToFix = tiles[wrongIdx]
            let targetIdx = tileToFix.correctId

            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                tiles.swapAt(wrongIdx, targetIdx)
            }
            
            // Penalty
            moves += 5
            timeElapsed += 30

            // Save game state after using hint
            saveGameState()

            checkWinCondition()
        }
    }
    
    private func checkWinCondition() {
        let isWin = tiles.enumerated().allSatisfy { index, tile in
            tile.correctId == index
        }
        
        if isWin {
            stopTimer()
            
            status = .animating
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
            
            let key: String
            switch gameMode {
            case .casual:
                key = "level_count_\(gridDimension)" // Casual levels are per grid size
                
                // Track Best Stats for Casual
                let timeKey = "casual_best_time_\(gridDimension)"
                let movesKey = "casual_best_moves_\(gridDimension)"
                
                let currentBestTime = UserDefaults.standard.double(forKey: timeKey)
                let currentBestMoves = UserDefaults.standard.integer(forKey: movesKey)
                
                // Update Best Time (lower is better, 0 means unset/none)
                if currentBestTime == 0 || timeElapsed < currentBestTime {
                    UserDefaults.standard.set(timeElapsed, forKey: timeKey)
                }
                
                // Update Best Moves
                if currentBestMoves == 0 || moves < currentBestMoves {
                    UserDefaults.standard.set(moves, forKey: movesKey)
                }
                
                // Refresh Published Properties
                loadBestStats()
                
            case .precision:
                key = "level_count_LADDER"
            case .pure:
                key = "level_count_CHALLENGE"
            }
            
            let currentWins = UserDefaults.standard.integer(forKey: key)
            UserDefaults.standard.set(currentWins + 1, forKey: key)
            
            winTask = Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    withAnimation { self.status = .won }
                }
            }
        }
    }
    
    private func startTimer() {
        stopTimer()
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if !Task.isCancelled && status == .playing {
                    await MainActor.run {
                        self.timeElapsed += 1
                    }
                }
            }
        }
    }
    
    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }
    
    private func loadBestStats() {
        if gameMode == .casual {
            let timeKey = "casual_best_time_\(gridDimension)"
            let movesKey = "casual_best_moves_\(gridDimension)"
            
            let t = UserDefaults.standard.double(forKey: timeKey)
            let m = UserDefaults.standard.integer(forKey: movesKey)
            
            bestTime = t > 0 ? t : nil
            bestMoves = m > 0 ? m : nil
        } else {
            bestTime = nil
            bestMoves = nil
        }
    }

    // MARK: - Game State Persistence

    private func saveGameState() {
        let cornersData: CornersData? = currentCorners.map { corners in
            CornersData(tl: corners.tl, tr: corners.tr, bl: corners.bl, br: corners.br)
        }

        let gameState = GameState(
            tiles: tiles,
            gridDimension: gridDimension,
            moves: moves,
            status: status,
            currentLevel: currentLevel,
            selectedTileId: selectedTileId,
            currentCorners: cornersData,
            minMoves: minMoves,
            moveLimit: moveLimit,
            gameMode: gameMode,
            timeElapsed: timeElapsed
        )

        do {
            let data = try JSONEncoder().encode(gameState)
            UserDefaults.standard.set(data, forKey: "savedGameState_\(gameMode.rawValue)")
        } catch {
            print("Failed to save game state: \(error)")
        }
    }

    private func loadGameState() {
        // Try to load specific mode state if known, but init() doesn't know mode yet.
        // We might need to load generic or default.
        // Actually, init() calls loadGameState(). At that point mode is .casual (default).
        // So it loads casual state.
        // If we switch mode later, we should reload.
        
        loadGameState(for: gameMode)
    }
    
    @discardableResult
    func loadGameState(for mode: GameMode) -> Bool {
        let key = "savedGameState_\(mode.rawValue)"
        
        // Migration: If no specific save, try legacy "savedGameState" ONLY for casual
        var data = UserDefaults.standard.data(forKey: key)
        if data == nil && mode == .casual {
             data = UserDefaults.standard.data(forKey: "savedGameState")
        }
        
        guard let data = data else { return false }

        do {
            let gameState = try JSONDecoder().decode(GameState.self, from: data)
            self.tiles = gameState.tiles
            self.gridDimension = gameState.gridDimension
            self.moves = gameState.moves
            self.status = gameState.status
            self.currentLevel = gameState.currentLevel
            self.selectedTileId = gameState.selectedTileId
            self.minMoves = gameState.minMoves ?? 0
            self.moveLimit = gameState.moveLimit ?? 0
            self.timeElapsed = gameState.timeElapsed ?? 0
            
            if self.status == .playing {
                startTimer() // Resume timer if loaded in playing state
            }

            if let cornersData = gameState.currentCorners {
                self.currentCorners = (tl: cornersData.tl, tr: cornersData.tr, bl: cornersData.bl, br: cornersData.br)
            }
            // Load mode, default to casual if missing (for legacy saves)
            self.gameMode = gameState.gameMode ?? .casual
            
            loadBestStats() // Load stats for current mode/grid
            
            return true
        } catch {
            print("Failed to load game state: \(error)")
            return false
        }
    }

    func clearGameState() {
        UserDefaults.standard.removeObject(forKey: "savedGameState_\(gameMode.rawValue)")
        if gameMode == .casual {
            UserDefaults.standard.removeObject(forKey: "savedGameState")
        }
    }
}

// MARK: - GameState Codable

private struct CornersData: Codable {
    let tl: RGBData
    let tr: RGBData
    let bl: RGBData
    let br: RGBData
}

private struct GameState: Codable {
    let tiles: [Tile]
    let gridDimension: Int
    let moves: Int
    let status: GameStatus
    let currentLevel: Int
    let selectedTileId: Int?
    let currentCorners: CornersData?
    let minMoves: Int?
    let moveLimit: Int?
    let gameMode: GameMode? // Optional for backward compatibility
    let timeElapsed: TimeInterval?
}
