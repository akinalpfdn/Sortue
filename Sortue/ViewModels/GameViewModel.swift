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
    
    var gridSize: (w: Int, h: Int) { difficulty.gridSize }
    
    init() {
        startNewGame()
    }
    
    // --- Game Lifecycle ---
    
    func startNewGame(difficulty: Difficulty? = nil) {
        if let d = difficulty { self.difficulty = d }
        
        // Reset State
        shuffleTask?.cancel()
        winTask?.cancel()
        status = .preview
        moves = 0
        selectedTileId = nil
        
        // Generate Colors
        let corners = (tl: Color.random, tr: Color.random, bl: Color.random, br: Color.random)
        let (w, h) = gridSize
        
        var newTiles: [Tile] = []
        var idCounter = 0
        
        for y in 0..<h {
            for x in 0..<w {
                let isCorner = (x == 0 && y == 0) || (x == w - 1 && y == 0) ||
                               (x == 0 && y == h - 1) || (x == w - 1 && y == h - 1)
                
                let color = Color.interpolated(x: x, y: y, width: w, height: h, corners: corners)
                
                newTiles.append(Tile(
                    id: idCounter,
                    correctId: idCounter,
                    color: color,
                    isFixed: isCorner,
                    currentIdx: idCounter
                ))
                idCounter += 1
            }
        }
        
        withAnimation {
            self.tiles = newTiles
        }
        
        // Schedule Shuffle
        shuffleTask = Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000) // 2.5s
            if !Task.isCancelled {
                await MainActor.run { shuffleBoard() }
            }
        }
    }
    
    private func shuffleBoard() {
        var mutableTiles = tiles.filter { !$0.isFixed }
        let fixedTiles = tiles.filter { $0.isFixed }
        
        mutableTiles.shuffle()
        
        var finalGrid = Array(repeating: Tile?.none, count: gridSize.w * gridSize.h)
        
        // Place fixed tiles back in their original slots
        for tile in fixedTiles {
            finalGrid[tile.correctId] = tile
        }
        
        // Fill gaps
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
    
    // --- Interaction ---
    
    func selectTile(_ tile: Tile) {
        guard status == .playing, !tile.isFixed else { return }
        
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()
        
        if let selectedId = selectedTileId {
            if selectedId == tile.id {
                // Deselect
                selectedTileId = nil
            } else {
                // Swap
                swapTiles(id1: selectedId, id2: tile.id)
                selectedTileId = nil
            }
        } else {
            // Select
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
        
        // Find first misplaced tile
        if let wrongIdx = tiles.firstIndex(where: { $0.correctId != tiles.firstIndex(of: $0) && !$0.isFixed }) {
            let tileToFix = tiles[wrongIdx]
            
            // Find where it belongs (which is currently occupied by someone else)
            // Since tiles are in an array, the "slot" is just the index.
            // We need to swap the tile at 'wrongIdx' with the tile at 'tileToFix.correctId'
            
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
            
            winTask = Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    withAnimation { self.status = .won }
                }
            }
        }
    }
}
