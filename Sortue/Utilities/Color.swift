import SwiftUI

// Extension to handle color math and generation
extension Color {
    // Generate a random color
    static var random: Color {
        return Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
    
    // Bilinear Interpolation to find the exact color for a grid coordinate
    static func interpolated(x: Int, y: Int, width: Int, height: Int, corners: (tl: Color, tr: Color, bl: Color, br: Color)) -> Color {
        let u = Double(x) / Double(width - 1)
        let v = Double(y) / Double(height - 1)
        
        // Extract components (using simple helper to get RGB from Color)
        let tl = corners.tl.components
        let tr = corners.tr.components
        let bl = corners.bl.components
        let br = corners.br.components
        
        // Interpolate top and bottom rows
        let rTop = lerp(start: tl.r, end: tr.r, t: u)
        let gTop = lerp(start: tl.g, end: tr.g, t: u)
        let bTop = lerp(start: tl.b, end: tr.b, t: u)
        
        let rBottom = lerp(start: bl.r, end: br.r, t: u)
        let gBottom = lerp(start: bl.g, end: br.g, t: u)
        let bBottom = lerp(start: bl.b, end: br.b, t: u)
        
        // Interpolate vertically
        return Color(
            red: lerp(start: rTop, end: rBottom, t: v),
            green: lerp(start: gTop, end: gBottom, t: v),
            blue: lerp(start: bTop, end: bBottom, t: v)
        )
    }
    
    // Linear Interpolation
    private static func lerp(start: Double, end: Double, t: Double) -> Double {
        return start * (1 - t) + end * t
    }
    
    // Helper to extract RGB components
    var components: (r: Double, g: Double, b: Double) {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
    }
    
    // Check minimal difference for equality
    func isSimilar(to other: Color) -> Bool {
        let c1 = self.components
        let c2 = other.components
        let threshold = 0.01
        return abs(c1.r - c2.r) < threshold && abs(c1.g - c2.g) < threshold && abs(c1.b - c2.b) < threshold
    }
}
