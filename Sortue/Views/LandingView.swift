import SwiftUI

struct LandingView: View {
    let onPlay: () -> Void
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            AmbientBackground() // Reusing from GameView.swift
            
            VStack(spacing: 40) {
                Spacer()
                
                // Title Section
                VStack(spacing: 16) {
                    Text("Sortue")
                        .font(.system(size: 60, weight: .bold, design: .serif))
                        .foregroundStyle(.primary)
                    
                    Text("landing_subtitle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Tutorial / Info Card
                VStack(spacing: 20) {
                    Image(systemName: "hand.draw.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.indigo)
                    
                    Text("how_to_play_title")
                        .font(.headline)
                    
                    Text("how_to_play_desc")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
                .padding(30)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Play Button
                Button(action: onPlay) {
                    HStack {
                        Text("start_game")
                            .fontWeight(.bold)
                            .font(.title3)
                        Image(systemName: "play.fill")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(Capsule())
                    .shadow(color: .indigo.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
}
