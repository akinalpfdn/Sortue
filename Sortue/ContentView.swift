import SwiftUI

struct ContentView: View {
    // This serves as the root container.
    // You can add global navigation, splash screens, or tab bars here later.
    var body: some View {
        GameView()
            .transition(.opacity)
    }
}
