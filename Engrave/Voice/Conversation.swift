import Foundation

enum AnswerMode: String, CaseIterable, Identifiable {
    case voice, typing

    var id: Self { self }
    var label: String { self == .voice ? "Speak" : "Type" }
    var icon: String { self == .voice ? "mic.fill" : "keyboard" }
}

/// The back-and-forth between the app and the person: the app talks, then waits for an answer
/// either by listening (voice mode) or for the text box (typing mode).
@MainActor
@Observable
final class Conversation {
    let mode: AnswerMode
    let listener: Listener
    private(set) var waitingForTyping = false
    private(set) var waitingToContinue = false
    private(set) var isCancelled = false

    @ObservationIgnored private var typed: CheckedContinuation<String, Never>?
    @ObservationIgnored private var proceed: CheckedContinuation<Void, Never>?

    init(mode: AnswerMode) {
        self.mode = mode
        listener = Listener()
    }

    func say(_ text: String) async {
        guard !isCancelled else { return }
        await Speaker.shared.speak(text)
    }

    func answer(hints: [String]) async -> String {
        guard !isCancelled else { return "" }
        switch mode {
        case .voice:
            return await listener.listen(hints: hints)
        case .typing:
            waitingForTyping = true
            let text = await withCheckedContinuation { typed = $0 }
            waitingForTyping = false
            return text
        }
    }

    func submitTyped(_ text: String) {
        typed?.resume(returning: text)
        typed = nil
    }

    /// In typing mode, waits for the Continue button. In voice mode it carries on by itself,
    /// so nothing needs a tap.
    func pause() async {
        guard mode == .typing, !isCancelled else { return }
        waitingToContinue = true
        await withCheckedContinuation { proceed = $0 }
        waitingToContinue = false
    }

    func continueTapped() {
        proceed?.resume()
        proceed = nil
    }

    func cancel() {
        isCancelled = true
        Speaker.shared.stop()
        listener.finish()
        submitTyped("")
        continueTapped()
    }
}
