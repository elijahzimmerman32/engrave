import AVFoundation
import Speech

/// Turns what the person says into text, on the device when the phone supports it.
@MainActor
@Observable
final class Listener {
    private(set) var transcript = ""
    private(set) var isListening = false

    @ObservationIgnored private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @ObservationIgnored private let engine = AVAudioEngine()
    @ObservationIgnored private var request: SFSpeechAudioBufferRecognitionRequest?
    @ObservationIgnored private var task: SFSpeechRecognitionTask?
    @ObservationIgnored private var timer: Task<Void, Never>?
    @ObservationIgnored private var continuation: CheckedContinuation<String, Never>?
    /// Bumped on every start and stop so callbacks from an earlier session are ignored.
    @ObservationIgnored private var session = 0

    static func requestPermission() async -> Bool {
        let speech = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0 == .authorized) }
        }
        guard speech else { return false }
        return await AVAudioApplication.requestRecordPermission()
    }

    /// Listens until the person pauses, then returns what they said ("" if nothing was heard).
    /// `hints` are words they're likely to say, which helps with names like "Yahweh".
    func listen(hints: [String] = [], pause: Double = 2.0, waitForSpeech: Double = 10) async -> String {
        finish()
        guard await Self.requestPermission(), let recognizer, recognizer.isAvailable else { return "" }
        AudioSession.activate()
        session += 1
        let id = session
        transcript = ""

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.contextualStrings = Array(hints.prefix(100))
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        self.request = request

        guard Self.startEngine(engine, feeding: request) else { return "" }
        isListening = true

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            task = Self.recognize(with: recognizer, request: request) { [weak self] text, isDone in
                Task { @MainActor in
                    guard let self, self.session == id else { return }
                    if let text, !text.isEmpty {
                        self.transcript = text
                        self.restartTimer(after: pause)
                    }
                    if isDone { self.finish() }
                }
            }
            restartTimer(after: waitForSpeech)
        }
    }

    /// Stops listening now and hands back whatever was heard so far.
    func finish() {
        timer?.cancel()
        timer = nil
        if engine.isRunning {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
        request?.endAudio()
        request = nil
        task?.cancel()
        task = nil
        session += 1
        isListening = false
        continuation?.resume(returning: transcript)
        continuation = nil
    }

    private func restartTimer(after seconds: Double) {
        timer?.cancel()
        timer = Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            self?.finish()
        }
    }

    // These run their closures on audio and recognition threads, so they're kept off the main actor.

    nonisolated private static func startEngine(_ engine: AVAudioEngine, feeding request: SFSpeechAudioBufferRecognitionRequest) -> Bool {
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0 else { return false }
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }
        engine.prepare()
        do {
            try engine.start()
            return true
        } catch {
            input.removeTap(onBus: 0)
            return false
        }
    }

    nonisolated private static func recognize(
        with recognizer: SFSpeechRecognizer,
        request: SFSpeechAudioBufferRecognitionRequest,
        update: @escaping @Sendable (String?, Bool) -> Void
    ) -> SFSpeechRecognitionTask {
        recognizer.recognitionTask(with: request) { result, error in
            update(result?.bestTranscription.formattedString, error != nil || result?.isFinal == true)
        }
    }
}
