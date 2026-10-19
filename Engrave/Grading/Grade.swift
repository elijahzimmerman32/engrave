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

    /// Below this, an answer is wrong no matter what the AI thinks.
    static let aiReviewFloor = 0.8

    static func grade(expected: String, answer: String) async -> Grade {
        var grade = TextMatcher.compare(expected: expected, answer: answer)

        // The word check is strict, and speech recognition sometimes mishears ("Yahweh" as "Yahway").
        // For answers that are close but short of passing, the on-device AI decides whether the
        // differences are only mishearings. It can't pass anything further off than that, and it
        // never fails an answer the word check passed.
        if !grade.passed, grade.score >= aiReviewFloor,
           await AICoach.isOnlyMisheard(expected: expected, answer: answer, grade: grade) {
            grade.passed = true
        }

        // Feedback always comes from the final verdict, so it can never praise a wrong answer.
        grade.feedback = TextMatcher.feedback(for: grade)
        return grade
    }
}
