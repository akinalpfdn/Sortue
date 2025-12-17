import SwiftUI
struct ContentView: View {
    @StateObject private var rateManager = RateManager.shared
    @State private var appState: AppState = .modeSelection
    @State private var showAbout = false
    @State private var showSettings = false
    
    enum AppState: Equatable {
        case landing
        case modeSelection
        case game(GameMode)
    }

    var body: some View {
        ZStack {
            switch appState {
            case .landing:
                LandingView(onDismiss: {
                    withAnimation { appState = .modeSelection }
                })
                .transition(.opacity)
                .zIndex(2)
                
            case .modeSelection:
                ModeSelectionView(
                    onStartGame: { mode in
                        withAnimation { appState = .game(mode) }
                    },
                    onSettingsClick: { withAnimation { showSettings = true } },
                    onAboutClick: { withAnimation { showAbout = true } }
                )
                .transition(.opacity)
                .zIndex(1)
                
            case .game(let mode):
                GameView(
                    mode: mode,
                    onBack: {
                        withAnimation { appState = .modeSelection }
                    }
                )
                .transition(.opacity)
                .zIndex(0)
            }
            
            // Rate Popup logic
            if rateManager.showRatePopup && appState != .landing {
                RateOverlay(
                    onRate: rateManager.rateNow,
                    onRemind: rateManager.remindMeLater
                )
                .zIndex(100)
            }
            
            if showAbout {
                AboutOverlay(onDismiss: { withAnimation { showAbout = false } })
                    .zIndex(100)
            }
            
            if showSettings {
                SettingsOverlay(onDismiss: { withAnimation { showSettings = false } })
                    .zIndex(100)
            }
        }
        .onAppear {
            if rateManager.currentLaunchCount == 0 {
                appState = .landing
            }
        }
    }
}
