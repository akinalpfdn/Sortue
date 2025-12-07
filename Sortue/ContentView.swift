import SwiftUI
struct ContentView: View {
    @StateObject private var rateManager = RateManager.shared
    @State private var showLanding = true

    var body: some View {
        ZStack {
            if showLanding {
                LandingView(onDismiss: {
                    withAnimation { showLanding = false }
                })
                .transition(.opacity)
                .zIndex(1)
            } else {
                GameView()
                    .transition(.opacity)
                    .zIndex(0)
            }
            
            if rateManager.showRatePopup && !showLanding {
                RateOverlay(
                    onRate: rateManager.rateNow,
                    onRemind: rateManager.remindMeLater
                )
                .zIndex(100) // Ensure it stays on top
            }
        }
        .onAppear {
            showLanding = rateManager.currentLaunchCount == 0
        }
    }
}
