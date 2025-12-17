import SwiftUI

struct WinOverlay: View {
    let onReplay: () -> Void
    let onNext: () -> Void
    
    // State to hold randomized text
    @State private var title: String = ""
    @State private var subtitle: String = ""
    
    // Theme-based random selection
    private let titles = WinMessages.titles
    
    private let subtitles = WinMessages.subtitles
    
    
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
                            Text("next_level")
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
            title = titles.randomElement() ?? titles[0]
            subtitle = subtitles.randomElement() ?? subtitles[0]
        }
    }
}
