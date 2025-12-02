import SwiftUI

struct GameView: View {
    @StateObject private var vm = GameViewModel()
    @Namespace private var animation
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            AmbientBackground()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    StatusIcon(status: vm.status)
                    VStack(alignment: .leading) {
                        Text("Sortue").font(.title2).fontWeight(.bold)
                        Text("\(vm.difficulty.title) • \(vm.moves) Moves")
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
                
                // Difficulty Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Difficulty.allCases) { diff in
                            CapsuleButton(
                                text: diff.title,
                                isSelected: vm.difficulty == diff,
                                action: { vm.startNewGame(difficulty: diff) }
                            )
                        }
                    }
                    .padding(.horizontal).padding(.bottom)
                }
                .disabled(vm.status == .preview)
            }
            .blur(radius: vm.status == .won ? 5 : 0)
            
            if vm.status == .won {
                WinOverlay(
                    onReplay: { vm.startNewGame() },
                    onNext: {
                        let nextRaw = (vm.difficulty.rawValue + 1) % Difficulty.allCases.count
                        vm.startNewGame(difficulty: Difficulty(rawValue: nextRaw))
                    }
                )
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

// ... Reuse the other subviews (WinOverlay, CircleButton, etc.) from previous output ...
struct WinOverlay: View {
    let onReplay: () -> Void
    let onNext: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.2).ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                    .padding(.bottom, 10)
                
                Text("Beautiful!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Harmony restored.")
                    .foregroundColor(.secondary)
                
                HStack(spacing: 20) {
                    Button(action: onReplay) {
                        Label("Replay", systemImage: "arrow.counterclockwise")
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    Button(action: onNext) {
                        Label("Next Level", systemImage: "play.fill")
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.black)
                            .cornerRadius(12)
                    }
                }
                .padding(.top, 10)
            }
            .padding(40)
            .background(Color.white)
            .cornerRadius(25)
            .shadow(radius: 20)
            .transition(.scale.combined(with: .opacity))
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

struct CapsuleButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .foregroundColor(isSelected ? .white : .primary)
                .background(isSelected ? Color.black : Color.white)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
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
