import SwiftUI
import Combine

class GameViewModel: ObservableObject {
    @Published var tiles: [Tile] = []
    @Published var status: GameStatus = .preview
    @Published var gridDimension: Int = 4
    @Published var moves: Int = 0
    @Published var selectedTileId: Int? = nil
    
    @Published var currentLevel: Int = 1
    
    private var shuffleTask: Task<Void, Never>?
    private var winTask: Task<Void, Never>?
    
    private var currentCorners: (tl: RGBData, tr: RGBData, bl: RGBData, br: RGBData)?
    
    var gridSize: (w: Int, h: Int) { (gridDimension, gridDimension) }
    
    init() {
        startNewGame()
    }
    
    func startNewGame(dimension: Int? = nil, preserveColors: Bool = false) {
        if let d = dimension { self.gridDimension = d }
        
        // Update level for the current dimension
        self.currentLevel = UserDefaults.standard.integer(forKey: "level_count_\(gridDimension)") + 1
        
        shuffleTask?.cancel()
        winTask?.cancel()
        status = .preview
        moves = 0
        selectedTileId = nil
        
        let (w, h) = gridSize
        
        // 1. Generate corners
        let corners: (tl: RGBData, tr: RGBData, bl: RGBData, br: RGBData)
        
        if preserveColors, let current = currentCorners {
            corners = current
        } else {
            // Use Harmonious Strategy
            corners = generateHarmoniousCorners()
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
        shuffleTask = Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000) // 2.5s
            if !Task.isCancelled {
                await MainActor.run { shuffleBoard() }
            }
        }
    }
    
    // Generates aesthetically pleasing palettes using HSB Color Theory
    private func generateHarmoniousCorners() -> (tl: RGBData, tr: RGBData, bl: RGBData, br: RGBData) {
        var bestCorners: (tl: RGBData, tr: RGBData, bl: RGBData, br: RGBData)? = nil
        var maxMinDistanceFound: Double = 0.0 // Track the best distance found so far
        
        // INCREASED THRESHOLD: 0.25 -> 0.45
        // This forces colors to be mathematically much further apart.
        let targetMinDistance = 0.45
        
        // Retry loop to ensure distinct corners
        for _ in 0..<50 {
            // Base Hue: 0.0 to 1.0
            let baseHue = Double.random(in: 0...1)
            
            // High Contrast Palette settings
            // Force saturation to be either very high or very low (pastel) to avoid muddy middles
            let highSat = Double.random(in: 0.8...1.0)
            let lowSat = Double.random(in: 0.1...0.3)
            
            // Force brightness to be distinctly bright or dark
            let bright = Double.random(in: 0.9...1.0)
            let dark = Double.random(in: 0.3...0.5)
            
            // Palettes Strategies
            enum PaletteStrategy: CaseIterable {
                case analogous      // Neighbors on color wheel
                case complementary  // Opposites on color wheel
                case triadic        // Triangle on color wheel
                case warmCool       // Temperature shift
                case monochromatic  // Single hue, purely brightness/sat shift
            }
            
            let strategy = PaletteStrategy.allCases.randomElement()!
            
            var tl, tr, bl, br: RGBData
            
            switch strategy {
            case .analogous:
                // WIDENED SPREAD: 0.15 -> 0.4 range
                // Explicitly mix Bright/Dark and HighSat/LowSat
                tl = RGBData.fromHSB(h: baseHue, s: highSat, b: bright) // Vivid Bright
                tr = RGBData.fromHSB(h: (baseHue + 0.2).truncatingRemainder(dividingBy: 1), s: lowSat, b: bright) // Pastel Bright
                bl = RGBData.fromHSB(h: (baseHue + 0.3).truncatingRemainder(dividingBy: 1), s: highSat, b: dark) // Vivid Dark
                br = RGBData.fromHSB(h: (baseHue + 0.5).truncatingRemainder(dividingBy: 1), s: lowSat, b: dark) // Muted Dark
                
            case .complementary:
                let compHue = (baseHue + 0.5).truncatingRemainder(dividingBy: 1)
                tl = RGBData.fromHSB(h: baseHue, s: highSat, b: bright)
                tr = RGBData.fromHSB(h: baseHue, s: lowSat, b: dark)
                bl = RGBData.fromHSB(h: compHue, s: highSat, b: dark) // Contrast background
                br = RGBData.fromHSB(h: compHue, s: lowSat, b: bright)
                
            case .triadic:
                let h2 = (baseHue + 0.33).truncatingRemainder(dividingBy: 1)
                let h3 = (baseHue + 0.66).truncatingRemainder(dividingBy: 1)
                tl = RGBData.fromHSB(h: baseHue, s: highSat, b: bright)
                tr = RGBData.fromHSB(h: h2, s: lowSat, b: bright)
                bl = RGBData.fromHSB(h: h3, s: highSat, b: dark)
                br = RGBData.fromHSB(h: baseHue, s: 0.5, b: 0.5) // Anchor neutral
                
            case .warmCool:
                let warm = Double.random(in: 0.0...0.15) // Reds/Oranges
                let cool = Double.random(in: 0.5...0.7)  // Blues/Purples
                // Maximize contrast between the sets
                tl = RGBData.fromHSB(h: warm, s: 0.9, b: 0.9)
                tr = RGBData.fromHSB(h: warm, s: 0.3, b: 1.0) // Pastel warm
                bl = RGBData.fromHSB(h: cool, s: 0.9, b: 0.4) // Deep cool
                br = RGBData.fromHSB(h: cool, s: 0.2, b: 0.9) // Icy cool
                
            case .monochromatic:
                // Maximize luminance distance
                tl = RGBData.fromHSB(h: baseHue, s: 0.05, b: 1.0)  // Almost White
                tr = RGBData.fromHSB(h: baseHue, s: 0.4, b: 0.9)   // Light
                bl = RGBData.fromHSB(h: baseHue, s: 0.8, b: 0.6)   // Medium
                br = RGBData.fromHSB(h: baseHue, s: 1.0, b: 0.2)   // Very Dark
            }
            
            // Validate Distances
            let d1 = tl.distance(to: tr)
            let d2 = tl.distance(to: bl)
            let d3 = tr.distance(to: br)
            let d4 = bl.distance(to: br)
            
            // Check cross distance (TL to BR) to ensure overall gradient flow
            let dCross = tl.distance(to: br)
            
            let currentMin = min(d1, min(d2, min(d3, min(d4, dCross))))

            // Optimization: Keep track of the "best bad one" in case we never hit the target
            if currentMin > maxMinDistanceFound {
                maxMinDistanceFound = currentMin
                bestCorners = (tl, tr, bl, br)
            }

            if currentMin > targetMinDistance {
                return (tl, tr, bl, br)
            }
        }
        
        // Fallback Logic:
        // 1. Return the best candidate we found (if it was decent, e.g. > 0.3)
        // 2. Or force the High Contrast Primary set if everything was muddy
        
        if let best = bestCorners, maxMinDistanceFound > 0.3 {
            return best
        }
        
        // Absolute fail-safe: Primary Colors + Yellow
        return (
            RGBData(r: 1, g: 0, b: 0),
            RGBData(r: 0, g: 1, b: 0),
            RGBData(r: 0, g: 0, b: 1),
            RGBData(r: 1, g: 1, b: 0)
        )
    }
    
    private func shuffleBoard() {
        var mutableTiles = tiles.filter { !$0.isFixed }
        let fixedTiles = tiles.filter { $0.isFixed }
        
        mutableTiles.shuffle()
        
        var finalGrid = Array(repeating: Tile?.none, count: gridSize.w * gridSize.h)
        
        for tile in fixedTiles {
            finalGrid[tile.correctId] = tile
        }
        
        var mutIdx = 0
        for i in 0..<finalGrid.count {
            if finalGrid[i] == nil {
                finalGrid[i] = mutableTiles[mutIdx]
                mutIdx += 1
            }
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            self.tiles = finalGrid.compactMap { $0 }
            self.status = .playing
        }
    }
    
    func selectTile(_ tile: Tile) {
        guard status == .playing, !tile.isFixed else { return }
        
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()
        
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
    
    private func swapTiles(id1: Int, id2: Int) {
        guard let idx1 = tiles.firstIndex(where: { $0.id == id1 }),
              let idx2 = tiles.firstIndex(where: { $0.id == id2 }) else { return }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            tiles.swapAt(idx1, idx2)
        }
        moves += 1
        checkWinCondition()
    }
    
    func useHint() {
        guard status == .playing else { return }
        
        if let wrongIdx = tiles.firstIndex(where: { $0.correctId != tiles.firstIndex(of: $0) && !$0.isFixed }) {
            let tileToFix = tiles[wrongIdx]
            let targetIdx = tileToFix.correctId
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                tiles.swapAt(wrongIdx, targetIdx)
            }
            checkWinCondition()
        }
    }
    
    private func checkWinCondition() {
        let isWin = tiles.enumerated().allSatisfy { index, tile in
            tile.correctId == index
        }
        
        if isWin {
            status = .animating
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
            
            let key = "level_count_\(gridDimension)"
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
}
