import Foundation

/// Splits a verse into short phrases so it can be learned one piece at a time.
enum Chunker {
    static func chunks(for text: String, maxWords: Int = 8) -> [String] {
        // Break after punctuation, keeping any closing quote with the phrase it ends.
        var phrases: [String] = []
        var current = ""
        let characters = Array(text)
        var i = 0
        while i < characters.count {
            current.append(characters[i])
            if ",;:.!?".contains(characters[i]) {
                while i + 1 < characters.count, "”’\")".contains(characters[i + 1]) {
                    i += 1
                    current.append(characters[i])
                }
                phrases.append(current)
                current = ""
            }
            i += 1
        }
        phrases.append(current)
        phrases = phrases.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }

        // Join tiny phrases to a neighbor, then break up long ones.
        var merged: [String] = []
        for phrase in phrases {
            if let last = merged.last,
               wordCount(phrase) < 3 || wordCount(last) < 3,
               wordCount(last) + wordCount(phrase) <= maxWords {
                merged[merged.count - 1] = last + " " + phrase
            } else {
                merged.append(phrase)
            }
        }
        return merged.flatMap { split($0, maxWords: maxWords) }
    }

    /// Cuts a phrase in two when the person is struggling with it. Nil if it's already short.
    static func halve(_ phrase: String) -> [String]? {
        let words = phrase.split(separator: " ")
        guard words.count >= 4 else { return nil }
        let middle = words.count / 2
        return [words[..<middle].joined(separator: " "), words[middle...].joined(separator: " ")]
    }

    /// "For God so loved the world," becomes "F G s l t w," as a memory hint.
    static func firstLetters(_ text: String) -> String {
        text.split(separator: " ").map { word in
            let letters = word.filter { $0.isLetter }
            let trailing = word.reversed().prefix { !$0.isLetter }.reversed()
            return (letters.first.map(String.init) ?? "") + String(trailing)
        }.joined(separator: " ")
    }

    private static func split(_ phrase: String, maxWords: Int) -> [String] {
        let words = phrase.split(separator: " ")
        guard words.count > maxWords else { return [phrase] }
        let pieces = (words.count + maxWords - 1) / maxWords
        let size = (words.count + pieces - 1) / pieces
        return stride(from: 0, to: words.count, by: size).map {
            words[$0..<min($0 + size, words.count)].joined(separator: " ")
        }
    }

    private static func wordCount(_ text: String) -> Int {
        text.split(separator: " ").count
    }
}
