import AppKit

class SoundManager {
    static let shared = SoundManager()

    var isEnabled = true
    private var lastSoundIndex = -1

    // Bundled sound file names (will look for these in Sounds/ directory)
    private let completionSounds = ["ping-aa", "ping-bb", "ping-cc"]

    func playCompletion() {
        guard isEnabled else { return }

        // Try bundled sounds first
        var idx: Int
        repeat {
            idx = Int.random(in: 0..<completionSounds.count)
        } while idx == lastSoundIndex && completionSounds.count > 1
        lastSoundIndex = idx

        let name = completionSounds[idx]
        if let url = Bundle.main.url(forResource: name, withExtension: "mp3", subdirectory: "Sounds"),
           let sound = NSSound(contentsOf: url, byReference: true) {
            sound.play()
            return
        }

        // Fallback: system sound
        NSSound.beep()
    }
}
