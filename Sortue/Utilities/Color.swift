import SwiftUI

extension RGBData {
    /// Generates a random RGB color with values in the range [0.0, 1.0]
    ///
    /// This static property creates a completely random color by generating
    /// random values for each RGB component. Used primarily for testing
    /// and experimental color generation.
    ///
    /// - Returns: A new RGBData instance with random component values
    static var random: RGBData {
        return RGBData(
            r: Double.random(in: 0...1),
            g: Double.random(in: 0...1),
            b: Double.random(in: 0...1)
        )
    }

    /// Performs bilinear interpolation to calculate the color at a specific grid position
    ///
    /// This function creates smooth color gradients by interpolating between four corner colors.
    /// It uses a two-step process:
    /// 1. Horizontal interpolation along top and bottom edges
    /// 2. Vertical interpolation between the edge results
    ///
    /// The mathematical formula for bilinear interpolation is:
    /// f(x,y) = f(0,0)(1-u)(1-v) + f(1,0)u(1-v) + f(0,1)(1-u)v + f(1,1)uv
    /// where u and v are normalized coordinates
    ///
    /// - Parameters:
    ///   - x: The x-coordinate in the grid (0 to width-1)
    ///   - y: The y-coordinate in the grid (0 to height-1)
    ///   - width: Total width of the grid
    ///   - height: Total height of the grid
    ///   - corners: Tuple containing the four corner colors:
    ///     - tl: Top-left corner color
    ///     - tr: Top-right corner color
    ///     - bl: Bottom-left corner color
    ///     - br: Bottom-right corner color
    /// - Returns: RGBData representing the interpolated color at the specified position
    static func interpolated(x: Int, y: Int, width: Int, height: Int, corners: (tl: RGBData, tr: RGBData, bl: RGBData, br: RGBData)) -> RGBData {
        // Normalize coordinates to [0.0, 1.0] range
        // Using max(1, width-1) prevents division by zero for single-column/row grids
        let u = Double(x) / Double(max(1, width - 1))
        let v = Double(y) / Double(max(1, height - 1))

        // First pass: Interpolate along horizontal edges
        // These represent the color values at the target x position on top and bottom edges
        let rTop = lerp(start: corners.tl.r, end: corners.tr.r, t: u)
        let gTop = lerp(start: corners.tl.g, end: corners.tr.g, t: u)
        let bTop = lerp(start: corners.tl.b, end: corners.tr.b, t: u)

        let rBottom = lerp(start: corners.bl.r, end: corners.br.r, t: u)
        let gBottom = lerp(start: corners.bl.g, end: corners.br.g, t: u)
        let bBottom = lerp(start: corners.bl.b, end: corners.br.b, t: u)

        // Second pass: Interpolate vertically between the horizontal results
        // This gives us the final color at the exact (x,y) position
        return RGBData(
            r: lerp(start: rTop, end: rBottom, t: v),
            g: lerp(start: gTop, end: gBottom, t: v),
            b: lerp(start: bTop, end: bBottom, t: v)
        )
    }

    /// Performs linear interpolation between two double values
    ///
    /// Linear interpolation (lerp) calculates a value between start and end based on
    /// the interpolation parameter t. The formula is:
    /// result = start * (1 - t) + end * t
    ///
    /// When t = 0.0, returns start
    /// When t = 1.0, returns end
    /// When t = 0.5, returns the midpoint
    ///
    /// - Parameters:
    ///   - start: The starting value (when t = 0.0)
    ///   - end: The ending value (when t = 1.0)
    ///   - t: Interpolation parameter, typically in range [0.0, 1.0]
    /// - Returns: Interpolated value between start and end
    private static func lerp(start: Double, end: Double, t: Double) -> Double {
        return start * (1.0 - t) + end * t
    }
}
