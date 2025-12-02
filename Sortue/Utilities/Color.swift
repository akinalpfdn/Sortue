import SwiftUI

extension RGBData {
    // Generate random RGB
    static var random: RGBData {
        return RGBData(
            r: Double.random(in: 0...1),
            g: Double.random(in: 0...1),
            b: Double.random(in: 0...1)
        )
    }
    
    // Bilinear Interpolation logic
    static func interpolated(x: Int, y: Int, width: Int, height: Int, corners: (tl: RGBData, tr: RGBData, bl: RGBData, br: RGBData)) -> RGBData {
        let u = Double(x) / Double(max(1, width - 1))
        let v = Double(y) / Double(max(1, height - 1))
        
        // Interpolate top edge (horizontal)
        let rTop = lerp(start: corners.tl.r, end: corners.tr.r, t: u)
        let gTop = lerp(start: corners.tl.g, end: corners.tr.g, t: u)
        let bTop = lerp(start: corners.tl.b, end: corners.tr.b, t: u)
        
        // Interpolate bottom edge (horizontal)
        let rBottom = lerp(start: corners.bl.r, end: corners.br.r, t: u)
        let gBottom = lerp(start: corners.bl.g, end: corners.br.g, t: u)
        let bBottom = lerp(start: corners.bl.b, end: corners.br.b, t: u)
        
        // Interpolate vertical
        return RGBData(
            r: lerp(start: rTop, end: rBottom, t: v),
            g: lerp(start: gTop, end: gBottom, t: v),
            b: lerp(start: bTop, end: bBottom, t: v)
        )
    }
    
    private static func lerp(start: Double, end: Double, t: Double) -> Double {
        return start * (1.0 - t) + end * t
    }
}
