import Foundation

/// Learning a verse piece by piece: hear a piece, then say everything learned so far.
/// If the person keeps missing a piece, it's split into a smaller one. It ends with a test
/// of the whole verse from memory.
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
    /// True once every piece is learned and the closing test of the whole verse has started.
    private(set) var isFinalTest = false
    /// The result of the closing test, if the person answered it.
    private(set) var finalGrade: Grade?

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
        let praise = ["Nice.", "Good.", "That's it.", "Well done."]

        phase = .starting
        await talk.say("Let's learn \(verse.reference.spoken). Here's the whole thing.")
        await talk.say(verse.text)

        var needsToHear = true
        var misses = 0
        var silentTurns = 0

        while step < chunks.count, !talk.isCancelled {
            if needsToHear {
                phase = .hearing
                await talk.say(step == 0 ? "Repeat after me." : "Now add this.")
                await talk.say(newPiece)
            }
            phase = .answering
            if talk.mode == .voice {
                await talk.say(step == 0 ? "Your turn." : "From the beginning.")
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
                await talk.say("I didn't hear anything. Here it is again. \(target)")
                continue
            }
            silentTurns = 0

            phase = .checking
            let grade = await Grader.grade(expected: target, answer: said)
            lastGrade = grade
            phase = .result

            if grade.passed {
                misses = 0
                needsToHear = true
                step += 1
                await talk.say(step == chunks.count ? "That's the whole verse!" : praise.randomElement()!)
            } else {
                misses += 1
                if misses >= 2, let halves = Chunker.halve(newPiece) {
                    chunks.replaceSubrange(step...step, with: halves)
                    misses = 0
                    needsToHear = true
                    await talk.say("Let's take a smaller piece.")
                } else {
                    needsToHear = false
                    await talk.say(grade.feedback)
                    await talk.say("Listen again. \(target)")
                }
            }
            await talk.pause()
        }

        guard !talk.isCancelled else { return }
        verse.practiceCount += 1

        // Finish with a test: the reference only, and the whole verse from memory.
        isFinalTest = true
        phase = .answering
        await talk.say("Now the test. Say the whole verse from memory. \(verse.reference.spoken)")
        let said = await talk.answer(hints: hints)
        guard !talk.isCancelled else { return }

        if !said.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            phase = .checking
            let grade = await Grader.grade(expected: verse.text, answer: said)
            verse.recordTest(grade)
            finalGrade = grade
        }
        phase = .finished
        if let grade = finalGrade {
            await talk.say(grade.passed ? "You've got it memorized! \(grade.feedback)" : "Almost. \(grade.feedback) Practice it again soon.")
        } else {
            await talk.say("Good practice. Try the test when you're ready.")
        }
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
