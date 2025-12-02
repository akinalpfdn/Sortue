import SwiftUI
import Combine

class GameViewModel: ObservableObject {
    @Published var tiles: [Tile] = []
    @Published var status: GameStatus = .preview
    @Published var difficulty: Difficulty = .relaxed
    @Published var moves: Int = 0
    @Published var selectedTileId: Int? = nil
    
    private var shuffleTask: Task<Void, Never>?
    private var winTask: Task<Void, Never>?
    
    private var currentCorners: (tl: RGBData, tr: RGBData, bl: RGBData, br: RGBData)?
    
    var gridSize: (w: Int, h: Int) { difficulty.gridSize }
    
    init() {
        startNewGame()
    }
    
    func startNewGame(difficulty: Difficulty? = nil, preserveColors: Bool = false) {
        if let d = difficulty { self.difficulty = d }
        
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
            corners = (
                tl: RGBData.random,
                tr: RGBData.random,
                bl: RGBData.random,
                br: RGBData.random
            )
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
    
    private func shuffleBoard() {
        // Separate mutable (movable) tiles from fixed corners
        var mutableTiles = tiles.filter { !$0.isFixed }
        let fixedTiles = tiles.filter { $0.isFixed }
        
        // Shuffle only the middle parts (and edges)
        mutableTiles.shuffle()
        
        // Reconstruct the grid array
        // We initialize an array of Optionals to fill it slot by slot
        var finalGrid = Array(repeating: Tile?.none, count: gridSize.w * gridSize.h)
        
        // 1. Put fixed tiles back exactly where they belong (Corners)
        for tile in fixedTiles {
            finalGrid[tile.correctId] = tile
        }
        
        // 2. Fill the remaining empty slots ('nil') with the shuffled tiles
        var mutIdx = 0
        for i in 0..<finalGrid.count {
            if finalGrid[i] == nil {
                finalGrid[i] = mutableTiles[mutIdx]
                mutIdx += 1
            }
        }
        
        // Force unwrap since we filled all slots
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
        
        // Find a tile that is NOT in its correct spot (and is not a corner)
        // 'index' is where it is NOW. 'correctId' is where it WANTS to be.
        if let wrongIdx = tiles.firstIndex(where: { $0.correctId != tiles.firstIndex(of: $0) && !$0.isFixed }) {
            let tileToFix = tiles[wrongIdx]
            let targetIdx = tileToFix.correctId // This is the array index where it belongs
            
            // Swap the tile at 'wrongIdx' with whatever is currently sitting at 'targetIdx'
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
            
            winTask = Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    withAnimation { self.status = .won }
                }
            }
        }
    }
}
