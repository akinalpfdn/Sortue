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

    @State private var path = NavigationPath()

    var body: some View {
        ZStack {
            // Rate Popup logic (global overlay)
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
            
            if appState == .landing {
                LandingView(onDismiss: {
                    withAnimation { appState = .modeSelection }
                })
                .transition(.opacity)
                .zIndex(2)
            } else {
                NavigationStack(path: $path) {
                    ModeSelectionView(
                        onStartGame: { mode in
                            path.append(mode)
                        },
                        onSettingsClick: { withAnimation { showSettings = true } },
                        onAboutClick: { withAnimation { showAbout = true } }
                    )
                    .navigationDestination(for: GameMode.self) { mode in
                        GameView(
                            mode: mode,
                            onBack: {
                                path.removeLast()
                            }
                        )
                        .navigationBarBackButtonHidden(true) // We will use custom button OR swipe
                        // If user wants NATIVE back navigation, usually that implies the back button in standard places OR just the swipe.
                        // If we hide the back button, the swipe gesture normally still works IF we enable it via UIGestureRecognizerDelegate trick or if we don't hide it.
                        // But user has a custom top bar in GameView.
                        // So we usually hide the system bar.
                        // When system bar is hidden, native swipe gesture is disabled by default in SwiftUI unless re-enabled.
                        // I will add the logic to re-enable swipe back gesture.
                    }
                }
                .zIndex(1)
            }
        }
        .onAppear {
            if rateManager.currentLaunchCount == 0 {
                appState = .landing
            }
        }
    }
}
