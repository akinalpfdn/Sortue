import SwiftUI

struct GameView: View {
    @StateObject private var vm = GameViewModel()
    @Namespace private var animation
    @State private var showAbout = false
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            AmbientBackground()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Button(action: { withAnimation { showAbout = true } }) {
                        StatusIcon(status: vm.status)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    VStack(alignment: .leading) {
                        Text("Sortue").font(.title2).fontWeight(.bold)
                        Text("Level \(vm.currentLevel) • \(vm.gridDimension)x\(vm.gridDimension) • \(vm.moves) Moves")
                            .font(.caption).foregroundColor(.gray).textCase(.uppercase)
                    }
                    Spacer()
                    HStack(spacing: 12) {
                        CircleButton(icon: "lightbulb.fill", action: vm.useHint)
                            .disabled(vm.status != .playing)
                        CircleButton(icon: "shuffle", action: { vm.startNewGame() })
                            .disabled(vm.status == .preview)
                    }
                }
                .padding(.horizontal).padding(.top)
                
                Spacer()
                
                // Game Grid
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: vm.gridSize.w),
                    spacing: 4
                ) {
                    ForEach(Array(vm.tiles.enumerated()), id: \.element.id) { index, tile in
                        TileView(
                            tile: tile,
                            isSelected: vm.selectedTileId == tile.id,
                            isWon: vm.status == .won || vm.status == .animating,
                            index: index,
                            gridWidth: vm.gridSize.w,
                            namespace: animation
                        )
                        .onTapGesture { vm.selectTile(tile) }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.05), radius: 20, x: 0, y: 10)
                )
                .padding()
                
                Spacer()
                
                // Grid Size Slider
                VStack(spacing: 10) {
                    HStack {
                        Text("Grid Size")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(vm.gridDimension)x\(vm.gridDimension)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { Double(vm.gridDimension) },
                            set: { newValue in
                                let newInt = Int(newValue)
                                if newInt != vm.gridDimension {
                                    vm.startNewGame(dimension: newInt, preserveColors: true)
                                }
                            }
                        ),
                        in: 4...12,
                        step: 1
                    )
                    .accentColor(.primary)
                }
                .padding(16)
                .background(.white.opacity(0))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal)
                .padding(.bottom)
            }
            .blur(radius: (vm.status == .won || showAbout) ? 5 : 0)
            
            if vm.status == .won {
                WinOverlay(
                    onReplay: { vm.startNewGame(preserveColors: true) },
                    onNext: {
                        let nextDim = min(vm.gridDimension + 1, 12)
                        vm.startNewGame(dimension: nextDim)
                    }
                )
            }
            
            if showAbout {
                AboutOverlay(onDismiss: { withAnimation { showAbout = false } })
                    .zIndex(200)
            }
            
            if vm.status == .animating {
                ParticleSystem()
            }
        }
    }
}

struct TileView: View {
    let tile: Tile
    let isSelected: Bool
    let isWon: Bool
    let index: Int
    let gridWidth: Int
    let namespace: Namespace.ID
    
    var body: some View {
        let x = index % gridWidth
        let y = index / gridWidth
        let delay = Double(x + y) * 0.05
        
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(tile.rgb.color) // Use the new .rgb.color accessor
                .aspectRatio(1, contentMode: .fit)
                .matchedGeometryEffect(id: tile.id, in: namespace)
                .overlay(
                    Group {
                        if tile.isFixed {
                            Circle()
                                .fill(.black.opacity(0.3))
                                .frame(width: 6, height: 6)
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white, lineWidth: isSelected ? 4 : 0)
                        .shadow(radius: isSelected ? 10 : 0)
                )
                .scaleEffect(isSelected ? 0.9 : 1.0)
                .scaleEffect(isWon ? 1.1 : 1.0)
                .offset(y: isWon ? -10 : 0)
                .animation(
                    isWon ? .spring(response: 0.4, dampingFraction: 0.5).delay(delay) : .default,
                    value: isWon
                )
        }
    }
}

// MARK: - Redesigned Win Overlay
struct WinOverlay: View {
    let onReplay: () -> Void
    let onNext: () -> Void
    
    // State to hold randomized text
    @State private var title: String = ""
    @State private var subtitle: String = ""
    
    // Theme-based random selection
    private let titles = [
        "Divine", "Exquisite", "Radiant", "Sublime", "Flawless",
        "Brilliant", "Zen", "Perfect", "Harmony", "Masterpiece",
        "Serene", "Complete", "Elegant", "Sorted", "Pure","Beautiful", "Serene", "Perfect", "Sublime", "Radiant",
        "Tranquil", "Lovely", "Splendid", "Graceful", "Harmonious",
        "Excellent", "Wonderful", "Calming", "Peaceful", "Brilliant",
        "Flowing", "Gentle", "Smooth", "Balanced", "Aligned"
    ]
    
    private let subtitles = [
        "The spectrum is complete.", "Balance has been restored.", "A vision of order.",
        "Colors aligned perfectly.", "Chaos into order.", "Simply satisfying.",
        "Peaceful perfection.", "A moment of clarity.", "Smooth transitions.",
        "You have an eye for this.", "Gradient mastery.", "Flow state achieved.",
        "Absolute tranquility.", "Beautifully organized.", "Rhythm and hue.","Harmony restored.", "A moment of peace.", "Colors in sync.", "Order found.",
        "Pure satisfaction.", "Simply delightful.", "A gentle success.", "Balance achieved.",
        "Smooth perfection.", "Calm and clear.", "The spectrum flows.", "Relax and breathe.",
        "Well sorted.", "A perfect gradient.", "Zen achieved.", "Flow state found.",
        "Nice and tidy.", "Softly aligned.", "Vibrant peace.", "Quietly perfect."
    ]
    
    
    var body: some View {
        ZStack {
            // Darker dim for better contrast
            Color.black.opacity(0.2).ignoresSafeArea()
            
            // Premium Glass Card
            VStack(spacing: 30) {
                
                // Animated Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: [.indigo.opacity(0.2), .purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(
                            LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }
                .padding(.top, 10)
                
                // Typography
                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 32, weight: .medium, design: .serif)) // Serif for premium look
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                // Actions
                HStack(spacing: 20) {
                    // Secondary Action (Replay)
                    Button(action: onReplay) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.primary.opacity(0.8))
                            .frame(width: 50, height: 50)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    // Primary Action (Next)
                    Button(action: onNext) {
                        HStack {
                            Text("Next Level")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                           .primary.opacity(0.5)
                        )
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(.horizontal, 10)
            }
            .padding(32)
            .background(.ultraThinMaterial) // Frost effect
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(.white.opacity(0.4), lineWidth: 1) // Glass border
            )
            .shadow(color: .black.opacity(0.15), radius: 30, x: 0, y: 15) // Deep shadow
            .padding(24)
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        }
        .onAppear {
            // Randomize on appear
            title = titles.randomElement() ?? "Divine"
            subtitle = subtitles.randomElement() ?? "Harmony restored."
        }
    }
}

struct CircleButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
                .frame(width: 44, height: 44)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
}



struct StatusIcon: View {
    let status: GameStatus
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .frame(width: 44, height: 44)
                .shadow(color: .black.opacity(0.05), radius: 4)
            
            if status == .preview {
                Image(systemName: "eye")
                    .foregroundColor(.indigo)
            } else {
                Image(systemName: "square.grid.2x2")
                    .foregroundColor(.primary)
            }
        }
    }
}

struct AmbientBackground: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.purple.opacity(0.2))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: -100, y: -200)
            
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: 100, y: 300)
        }
    }
}

struct ParticleSystem: View {
    @State private var time = 0.0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                let angle = now.remainder(dividingBy: 3) * 360
                
                for i in 0..<20 {
                    var x = size.width / 2 + cos(Double(i) + now * 2) * 100
                    var y = size.height / 2 + sin(Double(i) + now * 3) * 100
                    
                    let offset = Double(i) * 20
                    x += cos(now + offset) * 50
                    y += sin(now + offset) * 50
                    
                    let rect = CGRect(x: x, y: y, width: 8, height: 8)
                    context.fill(Path(ellipseIn: rect), with: .color(.yellow.opacity(0.8)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}
