import SwiftUI
import StoreKit
import Combine
class RateManager: ObservableObject {
    static let shared = RateManager()
    
    @AppStorage("app_launch_count") private var launchCount: Int = 0
    @AppStorage("next_review_threshold") private var nextReviewThreshold: Int = 10

    @Published var showRatePopup: Bool = false

    var currentLaunchCount: Int { launchCount }
    
    func appDidLaunch() {
        launchCount += 1
        print("App Launch Count: \(launchCount), Threshold: \(nextReviewThreshold)")
        
        if launchCount >= nextReviewThreshold {
            // Delay slightly to not annoy user immediately on startup
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.showRatePopup = true
            }
        }
    }
    
    func remindMeLater() {
        nextReviewThreshold = launchCount + 5
        showRatePopup = false
    }
    
    func rateNow() {
        // Push the next prompt far into the future so we don't ask again soon
        nextReviewThreshold = launchCount + 100 
        showRatePopup = false
        
        // Trigger the system review prompt
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}
