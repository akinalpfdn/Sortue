import SwiftUI

struct RateOverlay: View {
    let onRate: () -> Void
    let onRemind: () -> Void
    
    var body: some View {
        ZStack {
            // Darker dim for better contrast
            Color.black.opacity(0.4).ignoresSafeArea()
            
            // Premium Glass Card
            VStack(spacing: 30) {
                
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: [.yellow.opacity(0.2), .orange.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "star.fill")
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(
                            LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }
                .padding(.top, 10)
                
                // Typography
                VStack(spacing: 8) {
                    Text("Enjoying Sortue?")
                        .font(.system(size: 28, weight: .medium, design: .serif))
                        .foregroundStyle(.primary)
                    
                    Text("If you enjoy using Sortue, would you mind taking a moment to rate it and help me? Thanks for your support!")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                }
                
                // Actions
                VStack(spacing: 12) {
                    // Primary Action (Rate Now)
                    Button(action: onRate) {
                        HStack {
                            Text("Rate Now")
                                .fontWeight(.semibold)
                            Image(systemName: "heart.fill")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(Capsule())
                        .shadow(color: .pink.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    
                    // Secondary Action (Remind Me Later)
                    Button(action: onRemind) {
                        Text("Remind Me Later")
                            .fontWeight(.medium)
                            .foregroundColor(.primary.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
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
    }
}
