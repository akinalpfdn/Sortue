import AVFoundation
import Combine
class AudioManager: ObservableObject {
    static let shared = AudioManager()
    var audioPlayer: AVAudioPlayer?

    func playBackgroundMusic() {
        // Look for the file in the main bundle
        // Note: If the file is in a folder reference, the path might be different, 
        // but usually Bundle.main.url(forResource:...) finds it if it's in the Copy Bundle Resources phase.
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
    
    func stopBackgroundMusic() {
        audioPlayer?.stop()
    }
}
