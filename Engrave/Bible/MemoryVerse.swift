import Foundation
import SwiftData

/// A verse (or short passage) the person has chosen to memorize, with their progress on it.
@Model
final class MemoryVerse {
    var book: String
    var chapter: Int
    var startVerse: Int
    var endVerse: Int
    var text: String
    var addedAt: Date
    var practiceCount: Int
    var testAttempts: Int
    var bestScore: Double
    var lastTestedAt: Date?
    /// When the person first passed a test on this verse. The time from `addedAt` to this
    /// is how long it took to memorize, which the leaderboard will use.
    var masteredAt: Date?

    init(reference: VerseReference, text: String) {
        book = reference.book
        chapter = reference.chapter
        startVerse = reference.startVerse
        endVerse = reference.endVerse
        self.text = text
        addedAt = .now
        practiceCount = 0
        testAttempts = 0
        bestScore = 0
    }

    var reference: VerseReference {
        VerseReference(book: book, chapter: chapter, startVerse: startVerse, endVerse: endVerse)
    }

    var isMastered: Bool { masteredAt != nil }

    func recordTest(_ grade: Grade) {
        testAttempts += 1
        bestScore = max(bestScore, grade.score)
        lastTestedAt = .now
        if grade.passed && masteredAt == nil {
            masteredAt = .now
        }
    }
}
