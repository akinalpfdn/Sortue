import SwiftUI

struct LandingView: View {
    // Action to dismiss the onboarding
    var onDismiss: () -> Void
    
    // Page state: 0-3 are content, 4 is the "trigger" to close
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 250/255, green: 250/255, blue: 250/255).ignoresSafeArea() // Off-white
            
            // Reusing AmbientBackground from GameView if available, else local version
            LandingAmbientBackground()
            
            VStack(spacing: 0) {
                // 1. Header (Skip Button)
                HStack {
                    Spacer()
                    // Hide Skip on the last content page
                    if currentPage < 3 {
                        Button(action: onDismiss) {
                            Text("Skip")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .frame(height: 50)
                
                // 2. Main Content Pager
                TabView(selection: $currentPage) {
                    OnboardingPageContent(page: 0)
                        .tag(0)
                    
                    OnboardingPageContent(page: 1)
                        .tag(1)
                    
                    OnboardingPageContent(page: 2)
                        .tag(2)
                    
                    OnboardingPageContent(page: 3)
                        .tag(3)
                    
                    // Dummy page for "Swipe to Finish" detection
                    Color.clear.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // 3. Bottom Controls
                VStack(spacing: 24) {
                    // Page Indicators
                    HStack(spacing: 8) {
                        ForEach(0..<4, id: \.self) { index in
                            let isSelected = (currentPage == index) || (currentPage == 4 && index == 3)
                            
                            Capsule()
                                .fill(isSelected ? Color.indigo : Color.gray.opacity(0.3))
                                .frame(width: isSelected ? 24 : 8, height: 8)
                                .animation(.spring(), value: currentPage)
                        }
                    }
                    
                    // Primary Action Button
                    Button(action: {
                        withAnimation {
                            if currentPage < 3 {
                                currentPage += 1
                            } else {
                                onDismiss()
                            }
                        }
                    }) {
                        HStack {
                            Text(currentPage >= 3 ? "Start Sorting" : "Continue")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            if currentPage < 3 {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.indigo)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .indigo.opacity(0.25), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        // Detect swipe to dummy page 4
        .onChange(of: currentPage) { newValue in
            if newValue == 4 {
                onDismiss()
            }
        }
    }
}

// MARK: - Page Content Wrapper

struct OnboardingPageContent: View {
    let page: Int
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Animation Container
            ZStack {
                switch page {
                case 0: WelcomeAnimation()
                case 1: SwapMechanicAnimation()
                case 2: AutoSolvingGridAnimation()
                case 3: DifficultyAnimation()
                default: EmptyView()
                }
            }
            .frame(width: 280, height: 280)
            .padding(.bottom, 32)
            
            // Text Content
            VStack(spacing: 12) {
                Text(titleForPage(page))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                Text(descriptionForPage(page))
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
    
    func titleForPage(_ page: Int) -> String {
        switch page {
        case 0: return "Welcome to Sortue"
        case 1: return "Swap & Solve"
        case 2: return "Find the Harmony"
        case 3: return "Challenge Yourself"
        default: return ""
        }
    }
    
    func descriptionForPage(_ page: Int) -> String {
        switch page {
        case 0: return "Relax your mind with beautiful color gradient puzzles."
        case 1: return "Drag any tile to swap it with another. Put the colors in the right place."
        case 2: return "Watch the colors flow. Solve the puzzle to reveal the perfect gradient."
        case 3: return "Adjust the grid size to match your mood, from casual 4x4 to expert 12x12."
        default: return ""
        }
    }
}

// MARK: - Page 2: Auto Solving Grid Animation

struct LandingTile: Identifiable, Equatable {
    let id: Int
    let correctId: Int
    let color: Color
    let isFixed: Bool
}

struct AutoSolvingGridAnimation: View {
    @State private var tiles: [LandingTile] = []
    @State private var isWon = false
    @State private var animationTask: Task<Void, Never>? = nil
    
    let gridSize = 4
    
    var body: some View {
        ZStack {
            if tiles.isEmpty {
                Color.clear
            } else {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: gridSize),
                    spacing: 4
                ) {
                    ForEach(tiles) { tile in
                        LandingTileView(
                            tile: tile,
                            isWon: isWon,
                            index: tiles.firstIndex(of: tile) ?? 0,
                            gridWidth: gridSize
                        )
                        // This id allows the spring animation to track identity across swaps
                        .id(tile.id)
                    }
                }
                .padding(8)
                .background(Color.white.opacity(0.01)) // Touch container
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .onAppear {
            startLoop()
        }
        .onDisappear {
            animationTask?.cancel()
        }
    }
    
    func startLoop() {
        animationTask?.cancel()
        
        // 1. Generate Solved State
        let solvedTiles = generateSolvedTiles()
        self.tiles = solvedTiles
        
        animationTask = Task { @MainActor in
            while !Task.isCancelled {
                // A. Reset & Shuffle
                isWon = false
                
                // Shuffle logic (keeping fixed corners)
                var movable = solvedTiles.filter { !$0.isFixed }.shuffled()
                var newGrid = Array(repeating: LandingTile?.none, count: gridSize * gridSize)
                
                // Place fixed tiles
                solvedTiles.filter { $0.isFixed }.forEach { newGrid[$0.correctId] = $0 }
                
                // Fill gaps
                var mIdx = 0
                for i in 0..<newGrid.count {
                    if newGrid[i] == nil {
                        newGrid[i] = movable[mIdx]
                        mIdx += 1
                    }
                }
                
                // Apply shuffled state
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.tiles = newGrid.compactMap { $0 }
                }
                
                try? await Task.sleep(nanoseconds: 1_000_000_000) // Wait 1s
                
                // B. Solve Loop
                var solving = true
                while solving && !Task.isCancelled {
                    // Find first wrong tile
                    if let wrongIndex = self.tiles.firstIndex(where: { $0.correctId != self.tiles.firstIndex(of: $0)! && !$0.isFixed }) {
                        
                        let tile = self.tiles[wrongIndex]
                        let correctPos = tile.correctId // Where it wants to go
                        
                        // Swap with animation
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            self.tiles.swapAt(wrongIndex, correctPos)
                        }
                        
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.3s delay between moves
                        
                    } else {
                        solving = false
                    }
                }
                
                // C. Win State
                withAnimation {
                    isWon = true
                }
                try? await Task.sleep(nanoseconds: 3_000_000_000) // Show win for 3s
            }
        }
    }
    
    func generateSolvedTiles() -> [LandingTile] {
        var generated: [LandingTile] = []
        
        // Colors matching Kotlin hex codes
        let c1 = Color(red: 0.25, green: 0.32, blue: 0.71) // 3F51B5 Indigo
        let c2 = Color(red: 0.88, green: 0.25, blue: 0.98) // E040FB Purple
        let c3 = Color(red: 0.00, green: 0.74, blue: 0.83) // 00BCD4 Cyan
        let c4 = Color(red: 0.09, green: 1.00, blue: 1.00) // 18FFFF Cyan Accent
        
        for y in 0..<gridSize {
            for x in 0..<gridSize {
                let xFrac = Double(x) / Double(gridSize - 1)
                let yFrac = Double(y) / Double(gridSize - 1)
                
                let top = mix(c1, c2, pct: xFrac)
                let bottom = mix(c3, c4, pct: xFrac)
                let finalColor = mix(top, bottom, pct: yFrac)
                
                let isFixed = (x == 0 && y == 0) || (x == gridSize - 1 && y == 0) ||
                              (x == 0 && y == gridSize - 1) || (x == gridSize - 1 && y == gridSize - 1)
                
                let id = y * gridSize + x
                generated.append(LandingTile(id: id, correctId: id, color: finalColor, isFixed: isFixed))
            }
        }
        return generated
    }
    
    // Simple color interpolation helper
    func mix(_ c1: Color, _ c2: Color, pct: Double) -> Color {
        guard let cc1 = UIColor(c1).cgColor.components,
              let cc2 = UIColor(c2).cgColor.components else { return c1 }
        
        let r = cc1[0] + (cc2[0] - cc1[0]) * CGFloat(pct)
        let g = cc1[1] + (cc2[1] - cc1[1]) * CGFloat(pct)
        let b = cc1[2] + (cc2[2] - cc1[2]) * CGFloat(pct)
        
        return Color(red: r, green: g, blue: b)
    }
}

struct LandingTileView: View {
    let tile: LandingTile
    let isWon: Bool
    let index: Int
    let gridWidth: Int
    
    var body: some View {
        let x = index % gridWidth
        let y = index / gridWidth
        let staggerDelay = Double(x + y) * 0.05
        
        let isCorrectlyPlaced = (tile.correctId == index) && !tile.isFixed
        
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(tile.color)
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    Group {
                        if tile.isFixed {
                            Circle()
                                .fill(Color.black.opacity(0.3))
                                .frame(width: 6, height: 6)
                        } else if isCorrectlyPlaced {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                )
                .scaleEffect(isCorrectlyPlaced ? 0.95 : 1.0)
                .scaleEffect(isWon ? 1.1 : 1.0)
                .offset(y: isWon ? -10 : 0)
                // Win Wave Animation
                .animation(
                    isWon ? .spring(response: 0.4, dampingFraction: 0.5).delay(staggerDelay) : .default,
                    value: isWon
                )
        }
    }
}

// MARK: - Page 0: Welcome Animation

struct WelcomeAnimation: View {
    @State private var scale: CGFloat = 0.95
    
    var body: some View {
        ZStack {
            // Pulse Background
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.indigo, Color.purple, Color.pink, Color.indigo],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(scale)
                .shadow(color: .purple.opacity(0.3), radius: 20, x: 0, y: 0)
            
            // White Center
            Circle()
                .fill(Color.white)
                .padding(6)
            
            // "S" Logo
            Text("S")
                .font(.system(size: 100, weight: .black))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.indigo, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .frame(width: 200, height: 200)
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: true)) {
                scale = 1.05
            }
        }
    }
}

// MARK: - Page 1: Swap Mechanic Animation

struct SwapMechanicAnimation: View {
    @State private var offset: CGFloat = 0
    @State private var isResetting = false
    
    var body: some View {
        ZStack {
            // Left Tile (Moves Right)
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.indigo)
                .frame(width: 80, height: 80)
                .shadow(radius: 8)
                .offset(x: -50 + offset)
                .opacity(isResetting ? 0 : 1)
            
            // Right Tile (Moves Left)
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple)
                .frame(width: 80, height: 80)
                .shadow(radius: 8)
                .offset(x: 50 - offset)
                .opacity(isResetting ? 0 : 1)
            
            // Finger
            Image(systemName: "hand.point.up.left.fill")
                .font(.system(size: 48))
                .foregroundColor(.black.opacity(0.5))
                .offset(x: -30 + offset, y: 30) // Follows left tile
                .opacity(isResetting ? 0 : 1)
        }
        .onAppear {
            animateSwap()
        }
    }
    
    func animateSwap() {
        // 1. Swap
        withAnimation(.easeInOut(duration: 1.0).delay(0.5)) {
            offset = 100
        }
        
        // 2. Reset (Invisible)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isResetting = true
            offset = 0
        }
        
        // 3. Re-appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
            withAnimation(.easeIn(duration: 0.4)) {
                isResetting = false
            }
        }
        
        // Loop
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            animateSwap()
        }
    }
}

// MARK: - Page 3: Difficulty Animation

struct DifficultyAnimation: View {
    @State private var isExpanded = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .frame(width: 200, height: 200)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(white: 0.9), lineWidth: 2)
                )
            
            let count = isExpanded ? 5 : 3
            let spacing: CGFloat = 4
            let availableWidth: CGFloat = 160
            let tileSize = (availableWidth - (CGFloat(count - 1) * spacing)) / CGFloat(count)
            
            VStack(spacing: spacing) {
                ForEach(0..<count, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(0..<count, id: \.self) { col in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    Color.indigo.opacity(
                                        0.3 + (Double(row + col) / Double(count * 2)) * 0.7
                                    )
                                )
                                .frame(width: tileSize, height: tileSize)
                        }
                    }
                }
            }
            .animation(.easeInOut(duration: 1.0), value: isExpanded)
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                isExpanded.toggle()
            }
        }
    }
}

// MARK: - Helpers

struct LandingAmbientBackground: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.1)
                
                Circle()
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .position(x: geometry.size.width * 0.1, y: geometry.size.height * 0.9)
            }
        }
        .ignoresSafeArea()
    }
}
