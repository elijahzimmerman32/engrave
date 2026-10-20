import Foundation

/// Learning a verse piece by piece, in one of two styles (see `PracticeStyle`):
/// - Pieces: each piece is heard and repeated on its own, then a last round puts the whole verse together.
/// - Build up: each round the app says everything so far plus the next piece, and the person repeats it.
/// Each round has to be said correctly 1 or 2 times in a row, as set in Settings.
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
    /// Correct recitations so far of the current round.
    private(set) var passesThisStep = 0
    /// Correct recitations in a row needed to move on.
    let passesNeeded: Int
    let style: PracticeStyle

    init(verse: MemoryVerse, mode: AnswerMode) {
        self.verse = verse
        conversation = Conversation(mode: mode)
        chunks = Chunker.chunks(for: verse.text)
        passesNeeded = AppSettings.repeats
        style = AppSettings.style
    }

    /// One round per piece. The pieces style adds a last round for the whole verse.
    var roundCount: Int { style == .pieces && chunks.count > 1 ? chunks.count + 1 : chunks.count }

    /// True in the pieces style's last round, when the pieces are put together.
    var isWholeRound: Bool { style == .pieces && chunks.count > 1 && step >= chunks.count }

    /// What the person should say this round.
    var target: String {
        let last = min(step, chunks.count - 1)
        if isWholeRound { return chunks.joined(separator: " ") }
        return style == .buildUp ? chunks[0...last].joined(separator: " ") : chunks[last]
    }

    /// The piece being learned this round, used when a hard piece is split in two.
    private var currentPiece: String { chunks[min(step, chunks.count - 1)] }

    func run() async {
        let talk = conversation
        let hints = Self.hints(for: verse.text)

        phase = .starting
        await talk.say("Let's learn \(verse.reference.spoken). Here's the whole thing.")
        await talk.say(verse.text, slow: true)

        var needsToHear = true
        var misses = 0
        var silentTurns = 0

        while step < roundCount, !talk.isCancelled {
            if needsToHear {
                phase = .hearing
                if isWholeRound {
                    await talk.say("Now put it all together.")
                } else if step == 0 && passesThisStep == 0 {
                    await talk.say("Repeat after me.")
                } else if style == .pieces {
                    await talk.say("Next piece.")
                }
                await talk.say(target, slow: true)
            }
            phase = .answering
            if talk.mode == .voice {
                // Build up keeps a quick back-and-forth rhythm, so it only prompts on the first round.
                if passesThisStep > 0 {
                    await talk.say("One more time.")
                } else if isWholeRound {
                    await talk.say("Say the whole verse.")
                } else if style == .pieces || step == 0 {
                    await talk.say("Your turn.")
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
                if passesThisStep < passesNeeded {
                    needsToHear = false
                    await talk.say("Correct. Say it once more.")
                } else {
                    passesThisStep = 0
                    needsToHear = true
                    step += 1
                    if step == roundCount {
                        await talk.say("Correct. That's the whole verse!")
                    } else {
                        await talk.say(passesNeeded == 1 ? "Correct." : "Correct, twice in a row.")
                    }
                }
            } else {
                // A miss starts the count over, so the two correct answers are in a row.
                passesThisStep = 0
                misses += 1
                if misses >= 2, !isWholeRound, let halves = Chunker.halve(currentPiece) {
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
