import SwiftUI
import UIKit

// Raw RGB Data structure to ensure mathematical precision
struct RGBData: Equatable, Codable {
    let r: Double
    let g: Double
    let b: Double
    
    // Helper to convert to SwiftUI Color for display
    var color: Color {
        Color(red: r, green: g, blue: b)
    }
    
    // Create RGBData from Hue, Saturation, Brightness
    static func fromHSB(h: Double, s: Double, b: Double) -> RGBData {
        let color = UIColor(hue: CGFloat(h), saturation: CGFloat(s), brightness: CGFloat(b), alpha: 1.0)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return RGBData(r: Double(red), g: Double(green), b: Double(blue))
    }
    
    // Helper to check distance between colors
    func distance(to other: RGBData) -> Double {
        let dr = r - other.r
        let dg = g - other.g
        let db = b - other.b
        return sqrt(dr*dr + dg*dg + db*db)
    }
    
    // Helper to check similarity
    func isSimilar(to other: RGBData) -> Bool {
        let threshold = 0.05
        return abs(r - other.r) < threshold &&
               abs(g - other.g) < threshold &&
               abs(b - other.b) < threshold
    }
}

struct Tile: Identifiable, Equatable, Codable {
    let id: Int             // Unique ID
    let correctId: Int      // The grid index where this tile SHOULD be
    let rgb: RGBData        // The color data
    let isFixed: Bool       // Is this a corner anchor?
    var currentIdx: Int     // Logic helper

    static func == (lhs: Tile, rhs: Tile) -> Bool {
        return lhs.id == rhs.id
    }
}

enum GameStatus: String, Codable {
    case preview
    case playing
    case animating
    case won
}

enum GameMode: String, CaseIterable, Codable {
    case casual
    case precision
    case pure
    
    var name: String {
        return self.rawValue.capitalized
    }
}
