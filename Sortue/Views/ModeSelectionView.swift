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
                    WheelPicker(
                        items: GameMode.allCases,
                        initialIndex: GameMode.allCases.firstIndex(of: selectedMode) ?? 0,
                        visibleItemsCount: 3,
                        itemHeight: 50,
                        onSelectionChanged: { index in
                            let modes = GameMode.allCases
                            if index >= 0 && index < modes.count {
                                selectedMode = modes[index]
                            }
                        }
                    ) { mode, isSelected in
                        Text(mode.name)
                            .font(.app(size: 22))
                            .fontWeight(isSelected ? .bold : .medium)
                            .tracking(2)
                            .foregroundColor(isSelected ? .black : .gray.opacity(0.6))
                    }
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
                    
                    
                    if(selectedMode != .casual )
                    {
                        Text("grid_Info")
                            .font(.app(.body)) // bodyLarge
                            .foregroundColor(selectedMode == .pure ? Color(red: 1.0, green: 0.5, blue: 0.5) : .gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .frame(height: 50)
                        
                        
                    }
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
