import SwiftUI

struct SolutionOverlay: View {
    let tiles: [Tile]
    let gridSize: (w: Int, h: Int)
    let namespace: Namespace.ID
    
    var body: some View {
        // Create a sorted version of tiles to show the solution
        let solvedTiles = tiles.sorted { $0.correctId < $1.correctId }
        
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
                .onTapGesture { /* Block taps */ }
            
            VStack(spacing: 16) {
                Text("Target Gradient")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top, 10)
                    .shadow(radius: 4)
                
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: gridSize.w),
                    spacing: 4
                ) {
                    ForEach(solvedTiles) { tile in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(tile.rgb.color)
                            .aspectRatio(1, contentMode: .fit)
                            .matchedGeometryEffect(id: tile.id, in: namespace)
                            // Optional: Show dots on fixed tiles in preview too
                            .overlay(
                                Group {
                                    if tile.isFixed {
                                        Circle()
                                            .fill(.black.opacity(0.3))
                                            .frame(width: 4, height: 4)
                                    }
                                }
                            )
                    }
                }
                .padding()
            }
        }
    }
}
