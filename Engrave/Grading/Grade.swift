import Foundation

struct Grade {
    enum WordStatus { case correct, missed }

    struct Word: Identifiable {
        let id: Int
        let text: String
        let status: WordStatus
    }

    /// 0 to 1: the share of the verse's words said in the right order, lowered by extra words.
    let score: Double
    /// The verse's words, each marked as said or missed.
    let words: [Word]
    /// Words that were said but aren't in the verse.
    let extraWords: [String]
    var passed: Bool
    var feedback: String

    var missedWords: [String] { words.filter { $0.status == .missed }.map(\.text) }
}

enum Grader {
    static let passMark = 0.9

    static func grade(expected: String, answer: String) async -> Grade {
        var grade = TextMatcher.compare(expected: expected, answer: answer)
        guard grade.score < 0.98, !answer.isEmpty,
              let review = await AICoach.review(expected: expected, answer: answer, grade: grade) else { return grade }

        // The word check is strict, and speech recognition sometimes mishears ("Yahweh" as "Yahway").
        // If the on-device AI says the recitation is right, accept it as long as it's reasonably close.
        // The AI can only help a close answer pass; it never fails one the word check already passed.
        if review.isCorrect && grade.score >= 0.75 {
            grade.passed = true
        }
        grade.feedback = review.feedback
        return grade
    }
}
