import SwiftUI

struct GameView: View {
    var mode: GameMode = .casual
    var onBack: (() -> Void)?
    
    @StateObject private var vm = GameViewModel()
    @Namespace private var animation
    @State private var showAbout = false
    @State private var showSettings = false
    @State private var showSolutionPreview = false // State for solution popup
    
    // Drag & Interaction State
    @State private var draggedTile: Tile?
    @State private var pressedTileId: Int?
    @State private var dragLocation: CGPoint = .zero
    @State private var isDragging = false
    @State private var gridRect: CGRect = .zero
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            AmbientBackground()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Menu {
                        Button(action: { withAnimation { showSettings = true } }) {
                            Label("settings", systemImage: "gearshape")
                        }
                        
                        if let onBack = onBack {
                            Button(action: onBack) {
                                Label("back_to_menu", systemImage: "arrow.left")
                            }
                        }
                        
                        Button(action: { withAnimation { showAbout = true } }) {
                            Label("about", systemImage: "info.circle")
                        }
                    } label: {
                        StatusIcon(status: vm.status)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Sortue").font(.app(.title2)).fontWeight(.bold)
                        if vm.gameMode == .precision {
                            let remaining = max(0, vm.moveLimit - vm.moves)
                            Text(String(format: NSLocalizedString("level_display_precision", comment: ""), vm.currentLevel, vm.gridDimension, vm.gridDimension, remaining))
                                .font(.app(.caption)).foregroundColor(.gray).textCase(.uppercase)
                        } else {
                            Text(String(format: NSLocalizedString("level_display", comment: ""), vm.currentLevel, vm.gridDimension, vm.gridDimension, vm.moves))
                                .font(.app(.caption)).foregroundColor(.gray).textCase(.uppercase)
                        }
                    }
                    Spacer()
                    
                }
                .padding(.horizontal).padding(.top)
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(format: NSLocalizedString("min_moves", comment: ""), vm.minMoves))
                            .font(.app(.subheadline))
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        if vm.gameMode == .casual {
                            if let bestTime = vm.bestTime {
                                let mins = Int(bestTime) / 60
                                let secs = Int(bestTime) % 60
                                Text(String(format: NSLocalizedString("best_time", comment: ""), String(format: "%d:%02d", mins, secs)))
                                    .font(.app(.caption))
                                    .foregroundColor(.secondary.opacity(0.8))
                            }
                            
                            if let bestMoves = vm.bestMoves {
                                Text(String(format: NSLocalizedString("best_moves", comment: ""), bestMoves))
                                    .font(.app(.caption))
                                    .foregroundColor(.secondary.opacity(0.8))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if vm.gameMode != .pure {
                        CircleButton(icon: "eye.fill", action: showPreview)
                            .disabled(vm.status != .playing || showSolutionPreview)
                    }
                    
                    if vm.gameMode == .casual {
                        CircleButton(icon: "lightbulb.fill", action: vm.useHint)
                            .disabled(vm.status != .playing)
                        CircleButton(icon: "shuffle", action: { vm.startNewGame() })
                            .disabled(vm.status == .preview)
                    }
                }
                .padding(.horizontal) 
                
                // Game Grid
                ZStack(alignment: .topLeading) {
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
                                status: vm.status, // Pass game status
                                showCheck: vm.gameMode != .pure,
                                namespace: animation
                            )
                            .opacity(draggedTile?.id == tile.id ? 0.0 : 1.0) // Hide original when dragging
                            .overlay(
                                // Highlight overlay for "Touch Down" visual feedback
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(pressedTileId == tile.id ? 0.3 : 0))
                            )
                            .gesture(
                                DragGesture(minimumDistance: 0, coordinateSpace: .named("GridSpace"))
                                    .onChanged { value in
                                        handleDragChanged(value, tile: tile)
                                    }
                                    .onEnded { value in
                                        handleDragEnded(value, tile: tile)
                                    }
                            )
                        }
                    }
                    .padding(16)
                    .background(
                        GeometryReader { geo in
                            Color.clear.onAppear {
                                gridRect = geo.frame(in: .named("GridSpace"))
                            }
                            .onChange(of: geo.frame(in: .named("GridSpace"))) { newFrame in
                                gridRect = newFrame
                            }
                        }
                    )
                    .coordinateSpace(name: "GridSpace")
                    
                    // Draggable Tile Overlay
                    if let draggedTile = draggedTile {
                        let cellSize = calculateCellSize(containerWidth: gridRect.width)
                        
                        TileView(
                            tile: draggedTile,
                            isSelected: true, // Highlight dragged tile
                            isWon: false,
                            index: 0, // Index doesn't matter for visual
                            gridWidth: vm.gridSize.w,
                            status: vm.status,
                            showCheck: vm.gameMode != .pure,
                            namespace: animation,
                            enableGeometryEffect: false
                        )
                        .frame(width: cellSize, height: cellSize)
                        .position(dragLocation)
                        .allowsHitTesting(false)
                    }
                }
                
                Spacer()
                
                // Grid Size Slider
                VStack(spacing: 10) {
                    HStack {
                        Text("grid_size")
                            .font(.app(.subheadline))
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(vm.gridDimension)x\(vm.gridDimension)")
                            .font(.app(.subheadline))
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
                .opacity(vm.gameMode == .casual ? 1 : 0) // Hide slider if NOT casual
                .allowsHitTesting(vm.gameMode == .casual)
            }
            .blur(radius: (vm.status == .won || vm.status == .gameOver || showAbout || showSettings || showSolutionPreview) ? 5 : 0)
            
            if vm.status == .gameOver {
                GameOverOverlay(
                    onRetry: { vm.startNewGame(dimension: vm.gridDimension) },
                    onMenu: { onBack?() }
                )
                .zIndex(200)
            }
            
            if vm.status == .won {
                WinOverlay(
                    onReplay: { vm.startNewGame(preserveColors: true) },
                    onNext: { vm.startNewGame() }
                )
            }
            
            if showAbout {
                AboutOverlay(onDismiss: { withAnimation { showAbout = false } })
                    .zIndex(200)
            }
            
            if showSettings {
                SettingsOverlay(onDismiss: { withAnimation { showSettings = false } })
                    .zIndex(200)
            }
            
            // Solution Preview Modal
            if showSolutionPreview {
                SolutionOverlay(tiles: vm.tiles, gridSize: vm.gridSize, namespace: animation)
                    .zIndex(150)
            }
            
            if vm.status == .animating {
                ParticleSystem()
            }
            
            // Right Edge Back Gesture Zone (Emulates modern/Android back behavior)
            HStack {
                Spacer()
                Color.clear
                    .frame(width: 20)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                // Detect swipe from right to left
                                if value.translation.width < -50 {
                                    onBack?()
                                }
                            }
                    )
            }
        }
        .onAppear {
            if vm.gameMode != mode {
                vm.gameMode = mode
                // If the stored save doesn't match this mode (or we switched), we might reload or restart
                // Since vm init loads based on casual default, we need to explicitly reload for the new mode OR start new
                
                // Try loading for this mode
                if !vm.loadGameState(for: mode) {
                    // If no save exists for this mode, start a FRESH game
                    // This ensures we get new colors and state for the new mode
                    vm.startNewGame()
                }
            }
        }
    }
    
    // Logic to show preview for 2 seconds
    private func showPreview() {
        withAnimation { showSolutionPreview = true }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Auto-hide
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                showSolutionPreview = false
            }
        }
    }
    
    // MARK: - Interaction Logic
    
    private func handleDragChanged(_ value: DragGesture.Value, tile: Tile) {
        guard vm.status == .playing, !tile.isFixed else { return }
        
        if !isDragging {
            // Check if tile is "locked" (correct position) in Casual/Precision
            let isLocked = (tile.correctId == vm.tiles.firstIndex(of: tile)) && (vm.gameMode != .pure)
            if isLocked {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                return
            }

            // Check threshold
            if value.translation.width * value.translation.width + value.translation.height * value.translation.height > 100 { // 10px squared
                isDragging = true
                draggedTile = tile
                pressedTileId = nil // Clear press highlight
                vm.selectedTileId = nil // Clear any existing selection
                
                pressedTileId = nil // Clear press highlight
                vm.selectedTileId = nil // Clear any existing selection
            } else {
                pressedTileId = tile.id
            }
        }
        
        if isDragging {
            dragLocation = value.location
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value, tile: Tile) {
        pressedTileId = nil
        
        if isDragging {
            // Drop Logic
            if let dragged = draggedTile {
                // Find target
                if let targetIndex = calculateTargetIndex(at: value.location) {
                    // Ensure valid index and not fixed
                    if targetIndex >= 0 && targetIndex < vm.tiles.count {
                        let targetTile = vm.tiles[targetIndex]
                        
                        // Check if TARGET is locked
                        let isTargetLocked = (targetTile.correctId == targetIndex) && (vm.gameMode != .pure)
                        
                        if !targetTile.isFixed && targetTile.id != dragged.id {
                            if isTargetLocked {
                                // Prevent swapping into a locked tile
                                let generator = UINotificationFeedbackGenerator()
                                generator.notificationOccurred(.error)
                            } else {
                                vm.swapTiles(id1: dragged.id, id2: targetTile.id)
                            }
                        }
                    }
                }
            }
            
            // Reset
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                draggedTile = nil
                isDragging = false
            }
        } else {
            // Tap Logic
            // Prevent moving if already correct (and not just fixed), BUT ONLY for Casual/Precision
            let isLocked = (tile.correctId == vm.tiles.firstIndex(of: tile)) && (vm.gameMode != .pure)
            if vm.status == .playing && isLocked {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success) // Tiny haptic to say "it's locked"
                return
            }
            vm.selectTile(tile)
        }
    }
    
    private func calculateCellSize(containerWidth: CGFloat) -> CGFloat {
        let spacing: CGFloat = 4
        let columns = CGFloat(vm.gridSize.w)
        // Subtract padding if necessary, but gridRect comes from the Grid itself which includes padding?
        // LazyVGrid applies padding() modifier. The geometry reader is on the background of LazyVGrid.
        // So gridRect.width is the width of the grid content + padding.
        // Wait, LazyVGrid default spacing is 4.
        // The padding() modifier adds system padding (usually 16).
        // If GeoReader is on background of LazyVGrid (which has .padding()), it includes the padding.
        // So available width for cells = containerWidth - (padding * 2) - (spacing * (cols - 1))
        // But we don't know the exact padding value easily (it's platform dependent).
        // Better: Put GeoReader INSIDE the LazyVGrid? No, that repeats.
        
        // Alternative: Use the width from the TileView itself?
        // But we need it for the dragged tile frame.
        
        // Let's assume standard padding of 16 for now, or 0 if we can control it.
        // The code has `.padding()` on the LazyVGrid.
        // Let's assume the padding is included in gridRect.
        // Actually, let's remove the default .padding() and use explicit padding so we know the math.
        // Or just use the gridRect width and assume the padding is part of the visual but the cells fill the rest?
        // No, LazyVGrid with .padding() insets the content.
        
        // Let's try to estimate:
        // width = gridRect.width - 32 (16*2)
        // This is risky.
        
        // Better approach:
        // Calculate index based on relative position.
        // We can just rely on the ratio.
        
        let effectiveWidth = containerWidth - 32 // Approximate padding
        return (effectiveWidth - (columns - 1) * spacing) / columns
    }
    
    private func calculateTargetIndex(at point: CGPoint) -> Int? {
        // We need to map point (in GridSpace) to index.
        // GridSpace is the LazyVGrid bounds (including padding).
        
        let cols = vm.gridSize.w
        let rows = vm.gridSize.h
        let spacing: CGFloat = 4
        
        // Inset by padding
        let padding: CGFloat = 16
        let x = point.x - padding
        let y = point.y - padding
        
        let availableWidth = gridRect.width - (padding * 2)
        let availableHeight = gridRect.height - (padding * 2)
        
        let cellW = (availableWidth - CGFloat(cols - 1) * spacing) / CGFloat(cols)
        let cellH = cellW // Square cells
        
        // Check bounds
        if x < 0 || x > availableWidth || y < 0 || y > availableHeight {
            return nil
        }
        
        let col = Int(x / (cellW + spacing))
        let row = Int(y / (cellH + spacing))
        
        if col >= 0 && col < cols && row >= 0 && row < rows {
            return row * cols + col
        }
        
        return nil
    }
}



struct TileView: View {
    let tile: Tile
    let isSelected: Bool
    let isWon: Bool
    let index: Int
    let gridWidth: Int
    let status: GameStatus // Need status to check if we are playing
    var showCheck: Bool = true
    let namespace: Namespace.ID
    var enableGeometryEffect: Bool = true
    
    var body: some View {
        let x = index % gridWidth
        let y = index / gridWidth
        let delay = Double(x + y) * 0.05
        
        // Determine if placed correctly during gameplay
        // Fixed tiles are always "correct" but we treat them differently visually usually
        let isCorrectlyPlaced = (status == .playing) && (tile.correctId == index) && !tile.isFixed && showCheck
        
        ZStack {
            Group {
                if enableGeometryEffect {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(tile.rgb.color)
                        .aspectRatio(1, contentMode: .fit)
                        .matchedGeometryEffect(id: tile.id, in: namespace)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(tile.rgb.color)
                        .aspectRatio(1, contentMode: .fit)
                }
            }
                .overlay(
                    Group {
                        if tile.isFixed {
                            Circle()
                                .fill(.black.opacity(0.3))
                                .frame(width: 6, height: 6)
                        } else if isCorrectlyPlaced {
                            // "Locked" visual feedback for correctly placed mutable tiles
                            Image(systemName: "checkmark")
                                .font(.app(size: 12).weight(.bold))
                                .foregroundColor(.white.opacity(0.5))
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white, lineWidth: isSelected ? 4 : 0)
                        .shadow(radius: isSelected ? 10 : 0)
                )
                // Visual pop for correctly placed items
                .scaleEffect(isCorrectlyPlaced ? 0.95 : (isSelected ? 0.9 : 1.0))
                .scaleEffect(isWon ? 1.1 : 1.0)
                .offset(y: isWon ? -10 : 0)
                .animation(
                    isWon ? .spring(response: 0.4, dampingFraction: 0.5).delay(delay) : .spring(response: 0.3, dampingFraction: 0.7),
                    value: isCorrectlyPlaced
                )
                .animation(
                    isWon ? .spring(response: 0.4, dampingFraction: 0.5).delay(delay) : .default,
                    value: isWon
                )
                .onChange(of: isCorrectlyPlaced) { newValue in
                    if newValue {
                        let isHapticEnabled = UserDefaults.standard.bool(forKey: "hapticFeedbackEnabled")
                        if isHapticEnabled {
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                        }
                    }
                }
        }
    }
}



struct CircleButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.app(size: 18).weight(.semibold))
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
