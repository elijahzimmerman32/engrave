import Foundation

/// Learning a verse piece by piece: hear a piece, then say everything learned so far.
/// Each round has to be said correctly twice before the next piece is added.
/// If the person keeps missing a piece, it's split into a smaller one.
@MainActor
@Observable
final class PracticeSession {
    enum Phase { case starting, hearing, answering, checking, result, finished, stopped }

    let verse: MemoryVerse
    let conversation: Conversation
    private(set) var chunks: [String]
    private(set) var step = 0
    private(set) var phase = Phase.starting
    private(set) var lastGrade: Grade?
    /// Correct recitations so far of the current round. Two are needed to move on.
    private(set) var passesThisStep = 0
    static let passesNeeded = 2

    init(verse: MemoryVerse, mode: AnswerMode) {
        self.verse = verse
        conversation = Conversation(mode: mode)
        chunks = Chunker.chunks(for: verse.text)
    }

    /// The newest piece being added.
    var newPiece: String { chunks[min(step, chunks.count - 1)] }

    /// Everything the person should say this round: all pieces up to and including the newest.
    var target: String { chunks[0...min(step, chunks.count - 1)].joined(separator: " ") }

    func run() async {
        let talk = conversation
        let hints = Self.hints(for: verse.text)

        phase = .starting
        await talk.say("Let's learn \(verse.reference.spoken). Here's the whole thing.")
        await talk.say(verse.text, slow: true)

        var needsToHear = true
        var misses = 0
        var silentTurns = 0

        while step < chunks.count, !talk.isCancelled {
            if needsToHear {
                phase = .hearing
                await talk.say(step == 0 ? "Repeat after me." : "Now add this.")
                await talk.say(newPiece, slow: true)
            }
            phase = .answering
            if talk.mode == .voice {
                if passesThisStep > 0 {
                    await talk.say("One more time.")
                } else {
                    await talk.say(step == 0 ? "Your turn." : "From the beginning.")
                }
            }

            let said = await talk.answer(hints: hints)
            guard !talk.isCancelled else { return }

            if said.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                silentTurns += 1
                if silentTurns >= 2 {
                    phase = .stopped
                    await talk.say("I'll pause here. Come back anytime.")
                    return
                }
                needsToHear = false
                await talk.say("I didn't hear anything. Here it is again.")
                await talk.say(target, slow: true)
                continue
            }
            silentTurns = 0

            phase = .checking
            let grade = await Grader.grade(expected: target, answer: said)
            lastGrade = grade
            phase = .result

            if grade.passed {
                misses = 0
                passesThisStep += 1
                if passesThisStep < Self.passesNeeded {
                    needsToHear = false
                    await talk.say("Correct. Say it once more.")
                } else {
                    passesThisStep = 0
                    needsToHear = true
                    step += 1
                    await talk.say(step == chunks.count ? "Correct. That's the whole verse!" : "Correct, twice in a row.")
                }
            } else {
                // A miss starts the count over, so the two correct answers are in a row.
                passesThisStep = 0
                misses += 1
                if misses >= 2, let halves = Chunker.halve(newPiece) {
                    chunks.replaceSubrange(step...step, with: halves)
                    misses = 0
                    needsToHear = true
                    await talk.say("Let's take a smaller piece.")
                } else {
                    needsToHear = false
                    await talk.say(grade.feedback)
                    await talk.say("Listen again.")
                    await talk.say(target, slow: true)
                }
            }
            await talk.pause()
        }

        guard !talk.isCancelled else { return }
        phase = .finished
        verse.practiceCount += 1
        await talk.say("Great work. Now let's see if you've got it.")
    }

    func stop() {
        conversation.cancel()
    }

    /// The verse's words, given to speech recognition so it expects them.
    static func hints(for text: String) -> [String] {
        var seen = Set<String>()
        return text.split(whereSeparator: { $0.isWhitespace || $0 == "—" })
            .map { $0.filter { $0.isLetter || $0 == "’" || $0 == "'" } }
            .filter { !$0.isEmpty && seen.insert($0.lowercased()).inserted }
    }
}
