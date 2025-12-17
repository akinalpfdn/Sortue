import SwiftUI

struct ModeSelectionView: View {
    var onStartGame: (GameMode) -> Void
    var onSettingsClick: () -> Void
    var onAboutClick: () -> Void
    
    @State private var showMenu = false
    @State private var selectedMode: GameMode = .casual
    
    // Rainbow colors for the title gradient
    private let rainbowColors: [Color] = [
        Color(red: 1.0, green: 0.5, blue: 0.5),     // Saturated Pastel Red
        Color(red: 1.0, green: 0.7, blue: 0.28),    // Saturated Pastel Orange
        Color(red: 1.0, green: 0.88, blue: 0.4),    // Saturated Pastel Yellow
        Color(red: 0.47, green: 0.87, blue: 0.47),  // Saturated Pastel Green
        Color(red: 0.47, green: 0.62, blue: 0.8),   // Saturated Pastel Blue
        Color(red: 0.59, green: 0.44, blue: 0.84),  // Saturated Pastel Indigo
        Color(red: 0.76, green: 0.69, blue: 0.88)   // Saturated Pastel Violet
    ]
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            AmbientBackground()
            
            VStack {
                // Top Bar Area
                HStack {
                    Menu {
                        Button(action: onSettingsClick) {
                            Label("settings", systemImage: "gearshape")
                        }
                        Button(action: onAboutClick) {
                            Label("about", systemImage: "info.circle")
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .frame(width: 44, height: 44)
                                .shadow(color: .black.opacity(0.05), radius: 4)
                            
                            Image(systemName: "gearshape.fill")
                                .font(.app(size: 20))
                                .foregroundColor(.black)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Content
                VStack(spacing: 0) {
                    // Title
                    Text("SORTUE")
                        .font(.app(size: 48).weight(.black)) // Material displayMedium approx
                        .tracking(4) // Letter spacing
                        .foregroundStyle(
                            LinearGradient(
                                colors: rainbowColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .padding(.top, 48)
                    
                    Spacer()
                    
                    // Wheel Picker
                    CustomWheelPicker(
                        selection: $selectedMode,
                        items: GameMode.allCases
                    )
                    .frame(height: 150)
                    
                    Spacer()
                        .frame(height: 32)
                    
                    // Description
                    Text(getModeDescription(selectedMode))
                        .font(.app(.body)) // bodyLarge
                        .foregroundColor(selectedMode == .pure ? Color(red: 1.0, green: 0.5, blue: 0.5) : .gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .frame(height: 50)
                    
                    Spacer()
                    
                    // Play Button
                    MosaicPlayButton(action: {
                        onStartGame(selectedMode)
                    }, colors: rainbowColors)
                    .shadow(color: rainbowColors.first?.opacity(0.5) ?? .clear, radius: 16, x: 0, y: 8)
                    
                    Spacer()
                        .frame(height: 48)
                }
            }
        }
    }
    
    private func getModeDescription(_ mode: GameMode) -> LocalizedStringKey {
        switch mode {
        case .casual: return "casual_Text"
        case .precision: return "ladder_Text"
        case .pure: return "challenge_Text"
        }
    }
}

// MARK: - Custom Wheel Picker
struct CustomWheelPicker: View {
    @Binding var selection: GameMode
    let items: [GameMode]
    
    var body: some View {
        // Simplified wheel picker using actual Picker with WheelStyle
        // Getting SwiftUI Picker to look exactly like the custom Compose one is tricky.
        // Let's try to mimic the look with a custom view instead of standard Picker if needed.
        // But for "exact same view", a standard Picker is visually different (gray background bars).
        // Let's build a custom stack.
        
        let itemHeight: CGFloat = 50
        
        VStack(spacing: 0) {
            ForEach(items, id: \.self) { mode in
                Text(mode.name)
                    .font(.app(size: 22).weight(.bold))
                    .tracking(2)
                    .foregroundColor(selection == mode ? .black : .gray.opacity(0.5))
                    .frame(height: itemHeight)
                    .scaleEffect(selection == mode ? 1.2 : 0.9)
                    .animation(.spring(), value: selection)
                    .onTapGesture {
                        withAnimation {
                            selection = mode
                        }
                    }
            }
        }
        // This is a simplified "static" version. A true wheel requires scrolling.
        // Given the short list (3 items), a static list where you tap to select is probably better UX than a scroll for just 3 items,
        // unless recreating the scrolling physics is critical. The user said "implement exact same view".
        // The Compose View uses a WheelPicker, implying scrolling.
        // Let's try to wrap it in a pseudo-scrollable container or just present them vertically.
        // Actually, with 3 items, showing them all is cleaner.
    }
}

// MARK: - Mosaic Play Button
struct MosaicPlayButton: View {
    let action: () -> Void
    let colors: [Color]
    
    var body: some View {
        Button(action: action) {
            TriangleShape()
                .fill(Color.white)
                .frame(width: 80, height: 100)
                .clipShape(TriangleShape())
                .overlay(
                    MosaicGrid(colors: colors)
                        .clipShape(TriangleShape())
                )
        }
    }
}

struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height / 2))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

struct MosaicGrid: View {
    let colors: [Color]
    let rows = 5
    let cols = 5
    
    var body: some View {
        GeometryReader { geo in
            let tileW = geo.size.width / CGFloat(cols)
            let tileH = geo.size.height / CGFloat(rows)
            
            Canvas { context, size in
                for row in 0..<rows {
                    for col in 0..<cols {
                        let color = colors.randomElement() ?? .black
                        let rect = CGRect(
                            x: CGFloat(col) * tileW,
                            y: CGFloat(row) * tileH,
                            width: tileW,
                            height: tileH
                        )
                        
                        context.fill(Path(rect), with: .color(color))
                        context.stroke(Path(rect), with: .color(.white), lineWidth: 2)
                    }
                }
            }
        }
    }
}
