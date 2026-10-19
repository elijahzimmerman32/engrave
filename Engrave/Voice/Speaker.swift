import AVFoundation

enum AudioSession {
    /// One audio setup for both talking and listening, so the app can switch between them quickly.
    static func activate() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothA2DP, .duckOthers])
        try? session.setActive(true)
    }
}

/// Reads text aloud with the phone's built-in voice.
@MainActor
final class Speaker: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = Speaker()

    private let synthesizer = AVSpeechSynthesizer()
    private var current: ObjectIdentifier?
    private var continuation: CheckedContinuation<Void, Never>?

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// Speaks the text and returns once it has finished, or been stopped.
    /// `slow` is for verse text, so each word is clear enough to repeat back.
    func speak(_ text: String, slow: Bool = false) async {
        stop()
        guard !text.isEmpty else { return }
        AudioSession.activate()

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * (slow ? 0.75 : 0.95)
        utterance.postUtteranceDelay = slow ? 0.4 : 0.2
        current = ObjectIdentifier(utterance)

        await withCheckedContinuation { continuation in
            self.continuation = continuation
            synthesizer.speak(utterance)
        }
    }

    func stop() {
        current = nil
        synthesizer.stopSpeaking(at: .immediate)
        continuation?.resume()
        continuation = nil
    }

    private func finished(_ id: ObjectIdentifier) {
        // Ignore late callbacks from an utterance that was already replaced.
        guard id == current else { return }
        current = nil
        continuation?.resume()
        continuation = nil
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.finished(id) }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.finished(id) }
    }
}
