import SwiftUI

@main
struct SortueApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light) // Force light mode for clean aesthetic
                .onAppear {
                    AudioManager.shared.playBackgroundMusic()
                    RateManager.shared.appDidLaunch()
                }
        }
    }
}
