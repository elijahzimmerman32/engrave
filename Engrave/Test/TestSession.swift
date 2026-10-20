import Foundation

/// The test: the app reads a reference and the person recites the verse from memory.
@MainActor
@Observable
final class TestSession {
    enum Phase { case starting, asking, answering, checking, result, finished, stopped }

    struct Result: Identifiable {
        let id = UUID()
        let reference: String
        let grade: Grade
    }

    let verses: [MemoryVerse]
    let conversation: Conversation
    private(set) var index = 0
    private(set) var phase = Phase.starting
    private(set) var results: [Result] = []

    init(verses: [MemoryVerse], mode: AnswerMode) {
        self.verses = verses
        conversation = Conversation(mode: mode)
    }

    var current: MemoryVerse? { index < verses.count ? verses[index] : nil }
    var lastGrade: Grade? { results.last?.grade }

    func run() async {
        let talk = conversation
        phase = .starting
        if verses.count > 1 {
            await talk.say("\(verses.count) verses.")
        }

        var silentTurns = 0
        while index < verses.count, !talk.isCancelled {
            let verse = verses[index]
            phase = .asking
            await talk.say(verse.reference.spoken)

            phase = .answering
            let said = await talk.answer(hints: PracticeSession.hints(for: verse.text))
            guard !talk.isCancelled else { return }

            if said.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                silentTurns += 1
                if silentTurns >= 2 {
                    phase = .stopped
                    await talk.say("Pausing.")
                    return
                }
                continue
            }
            silentTurns = 0

            phase = .checking
            let grade = await Grader.grade(expected: verse.text, answer: said)
            verse.recordTest(grade)
            results.append(Result(reference: verse.reference.display, grade: grade))
            phase = .result

            // Only the verdict is spoken. The missed words are on screen.
            if grade.passed {
                await talk.say("Correct.")
            } else {
                await talk.say("Not quite.")
                await talk.say(verse.text, slow: true)
            }
            await talk.pause()
            index += 1
        }

        guard !talk.isCancelled else { return }
        phase = .finished
        let passed = results.filter(\.grade.passed).count
        if results.count > 1 {
            await talk.say("\(passed) out of \(results.count).")
        }
    }

    func stop() {
        conversation.cancel()
    }
}
