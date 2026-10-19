import Foundation
import FoundationModels

@Generable
struct MishearingCheck {
    @Guide(description: "True only if every difference between the verse and the recitation is a word that sounds almost the same, a spelling or number format difference, or punctuation. False if any word is missing, added, swapped for a different word, or out of order.")
    var onlyMisheard: Bool
}

/// Uses Apple's on-device AI (iPhone 15 Pro and newer, with Apple Intelligence turned on) to
/// forgive speech-recognition slips that the word check counts as mistakes. When the AI isn't
/// available, the app relies on the word check alone.
enum AICoach {
    static var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    static func isOnlyMisheard(expected: String, answer: String, grade: Grade) async -> Bool {
        guard isAvailable else { return false }
        let session = LanguageModelSession(instructions: """
            You check recitations of Bible verses that were captured by speech recognition. \
            Be strict: the person must say every word of the verse in order. Only forgive words \
            the speech recognizer could have misheard because they sound almost the same.
            """)
        let prompt = """
            The verse: \(expected)

            What the speech recognizer heard: \(answer)

            Words a word-by-word check couldn't find: \(grade.missedWords.joined(separator: ", "))
            Extra words it heard: \(grade.extraWords.isEmpty ? "none" : grade.extraWords.joined(separator: ", "))
            """
        do {
            return try await session.respond(to: prompt, generating: MishearingCheck.self).content.onlyMisheard
        } catch {
            return false
        }
    }
}
