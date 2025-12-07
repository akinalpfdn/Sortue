import AVFoundation
import Combine
class AudioManager: ObservableObject {
    static let shared = AudioManager()
    var audioPlayer: AVAudioPlayer?
    @Published var isMusicEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isMusicEnabled, forKey: "isMusicEnabled")
            if isMusicEnabled {
                playBackgroundMusic()
            } else {
                stopBackgroundMusic()
            }
        }
    }
    
    private init() {
        self.isMusicEnabled = UserDefaults.standard.object(forKey: "isMusicEnabled") as? Bool ?? true
    }

    func playBackgroundMusic() {
        guard isMusicEnabled else { return }
        
        // If already initialized, just play/resume
        if let player = audioPlayer {
            if !player.isPlaying {
                player.play()
            }
            return
        }

        // Look for the file in the main bundle
        guard let url = Bundle.main.url(forResource: "soundTrack", withExtension: "mp3") else {
            print("Could not find soundTrack.mp3 in the bundle.")
            return
        }

        do {
            // Configure audio session to mix with other audio (ambient)
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.volume = 0.7
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Error playing background music: \(error.localizedDescription)")
        }
    }
    
    func pauseBackgroundMusic() {
        audioPlayer?.pause()
    }
    
    func stopBackgroundMusic() {
        audioPlayer?.stop()
    }
}
