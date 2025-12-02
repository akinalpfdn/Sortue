import SwiftUI
struct ContentView: View {
    @StateObject private var rateManager = RateManager.shared

    var body: some View {
        ZStack {
            GameView()
                .transition(.opacity)
            
            if rateManager.showRatePopup {
                RateOverlay(
                    onRate: rateManager.rateNow,
                    onRemind: rateManager.remindMeLater
                )
                .zIndex(100) // Ensure it stays on top
            }
        }
    }
}
