import SwiftUI

struct GameOverOverlay: View {
    var onRetry: () -> Void
    var onMenu: () -> Void
    
    @State private var appear = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("GAME OVER")
                    .font(.app(.largeTitle))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                
                Text(NSLocalizedString("out_of_moves", comment: "Out of moves"))
                    .font(.app(.body))
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 20) {
                    Button(action: onMenu) {
                        HStack {
                            Image(systemName: "list.bullet")
                            Text("MENU")
                        }
                        .font(.app(.headline))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                )
                        )
                    }
                    
                    Button(action: onRetry) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("RETRY")
                        }
                        .font(.app(.headline))
                        .foregroundColor(Color.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(Color.white)
                        )
                    }
                }
            }
            .scaleEffect(appear ? 1 : 0.8)
            .opacity(appear ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appear = true
            }
        }
    }
}
