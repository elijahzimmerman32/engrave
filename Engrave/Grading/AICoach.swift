import Foundation
import FoundationModels

@Generable
struct VerseReview {
    @Guide(description: "True if the recitation has every word of the verse in order. Ignore punctuation, capitalization, how numbers are written, and words that sound alike, since speech recognition can mishear them.")
    var isCorrect: Bool

    @Guide(description: "One or two short, warm sentences spoken directly to the person. Say what they got right and name any words they missed or changed. At most 35 words. No quotation marks.")
    var feedback: String
}

/// Uses Apple's on-device AI (iPhone 15 Pro and newer, with Apple Intelligence turned on)
/// to judge close answers and give friendly, specific feedback. Returns nil when the AI
/// isn't available, and the app falls back to the plain word check.
enum AICoach {
    static var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    static func review(expected: String, answer: String, grade: Grade) async -> VerseReview? {
        guard isAvailable else { return nil }
        let session = LanguageModelSession(instructions: """
            You are a kind coach helping someone memorize Bible verses from the World English Bible. \
            You compare what they recited with the verse and tell them how they did.
            """)
        let prompt = """
            The verse: \(expected)

            What they recited: \(answer)

            Words an automatic check couldn't find: \(grade.missedWords.isEmpty ? "none" : grade.missedWords.joined(separator: ", "))
            Extra words they said: \(grade.extraWords.isEmpty ? "none" : grade.extraWords.joined(separator: ", "))
            """
        do {
            return try await session.respond(to: prompt, generating: VerseReview.self).content
        } catch {
            return nil
        }
    }
}
