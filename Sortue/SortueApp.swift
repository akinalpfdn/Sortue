import SwiftUI

@main
struct SortueApp: App {
    @Environment(\.scenePhase) var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light) // Force light mode for clean aesthetic
                .onAppear {
                    AudioManager.shared.playBackgroundMusic()
                    RateManager.shared.appDidLaunch()
                }
                .onChange(of: scenePhase) { newPhase in
                    switch newPhase {
                    case .active:
                        AudioManager.shared.playBackgroundMusic()
                    case .background, .inactive:
                        AudioManager.shared.pauseBackgroundMusic()
                    @unknown default:
                        break
                    }
                }
        }
    }
}
