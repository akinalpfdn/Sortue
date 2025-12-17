import SwiftUI

struct AboutOverlay: View {
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.4).ignoresSafeArea()
                .onTapGesture { onDismiss() }
            
            // Content Card
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.pink.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "heart.fill")
                        .font(.app(size: 36))
                        .foregroundStyle(
                            LinearGradient(colors: [.pink, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }
                .padding(.top, 8)
                
                Text("thanks_playing")
                    .font(.app(size: 30).weight(.bold))
                    .foregroundStyle(.primary)
                
                VStack(spacing: 16) {
                    Text("hope_enjoy")
                        .font(.app(.body))
                    
                    Text("simple_experience")
                        .font(.app(.body))
                    
                    Text("support_me")
                        .font(.app(.body).weight(.medium))
                    // Credit
                    Text("music_credit")
                        .font(.app(.body))
                        .foregroundStyle(.primary)
                        .padding(.top, 8)
                }
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary.opacity(0.8))
                .padding(.horizontal, 8)
                
                
                
                // Close Button
                Button(action: onDismiss) {
                    Text("close")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.primary)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                }
                .padding(.top, 16)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(.white.opacity(0.4), lineWidth: 1)
            )
            .padding(24)
            .shadow(color: .black.opacity(0.2), radius: 30, x: 0, y: 15)
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        }
    }
}
