import SwiftUI

// Represents a single tile on the board
struct Tile: Identifiable, Equatable {
    let id: Int             // Unique ID
    let correctId: Int      // The index where this tile SHOULD be
    let color: Color        // The calculated gradient color
    let isFixed: Bool       // Is this a corner anchor?
    var currentIdx: Int     // Helper for sorting logic
    
    // For Equatable
    static func == (lhs: Tile, rhs: Tile) -> Bool {
        return lhs.id == rhs.id
    }
}

// Difficulty settings
enum Difficulty: Int, CaseIterable, Identifiable {
    case relaxed = 0
    case balanced = 1
    case complex = 2
    
    var id: Int { self.rawValue }
    
    var title: String {
        switch self {
        case .relaxed: return "Relaxed"
        case .balanced: return "Balanced"
        case .complex: return "Complex"
        }
    }
    
    var gridSize: (w: Int, h: Int) {
        switch self {
        case .relaxed: return (4, 4)
        case .balanced: return (5, 5)
        case .complex: return (6, 6)
        }
    }
}

// Game Status State Machine
enum GameStatus {
    case preview    // Showing correct order
    case playing    // User interacting
    case animating  // Win animation playing
    case won        // Modal showing
}
