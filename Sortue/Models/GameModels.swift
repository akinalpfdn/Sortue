import SwiftUI

// Raw RGB Data structure to ensure mathematical precision
// We use this instead of SwiftUI.Color to avoid color space conversion issues
struct RGBData: Equatable, Codable {
    let r: Double
    let g: Double
    let b: Double
    
    // Helper to convert to SwiftUI Color for display
    var color: Color {
        Color(red: r, green: g, blue: b)
    }
    
    // Helper to check similarity
    func isSimilar(to other: RGBData) -> Bool {
        let threshold = 0.05
        return abs(r - other.r) < threshold &&
               abs(g - other.g) < threshold &&
               abs(b - other.b) < threshold
    }
}

struct Tile: Identifiable, Equatable {
    let id: Int             // Unique ID
    let correctId: Int      // The grid index where this tile SHOULD be
    let rgb: RGBData        // The color data
    let isFixed: Bool       // Is this a corner anchor?
    var currentIdx: Int     // Logic helper
    
    static func == (lhs: Tile, rhs: Tile) -> Bool {
        return lhs.id == rhs.id
    }
}

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

enum GameStatus {
    case preview
    case playing
    case animating
    case won
}
