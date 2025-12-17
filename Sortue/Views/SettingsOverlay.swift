import SwiftUI

struct SettingsOverlay: View {
    let onDismiss: () -> Void
    @ObservedObject private var audioManager = AudioManager.shared
    
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
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "gearshape.fill")
                        .font(.app(size: 36))
                        .foregroundStyle(Color.gray)
                }
                .padding(.top, 8)
                
                Text("settings")
                    .font(.app(size: 28).weight(.bold))
                    .foregroundStyle(.primary)
                
                // Settings List
                VStack(spacing: 20) {
                    HStack {
                        Image(systemName: "music.note")
                            .font(.app(size: 20))
                            .foregroundColor(.indigo)
                            .frame(width: 30)
                        
                        Text("music")
                            .font(.app(.body))
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Toggle("", isOn: $audioManager.isMusicEnabled)
                            .labelsHidden()
                            .tint(.indigo)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.5))
                    .cornerRadius(12)
                }
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
