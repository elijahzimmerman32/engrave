import Foundation

struct BibleBook: Decodable, Identifiable, Hashable {
    let name: String
    /// chapters[chapter - 1][verse - 1] is the verse text. A few verses are empty
    /// because the World English Bible leaves them out (for example Acts 8:37).
    let chapters: [[String]]

    var id: String { name }
}

struct VerseReference: Hashable {
    var book: String
    var chapter: Int
    var startVerse: Int
    var endVerse: Int

    /// "John 3:16" or "Psalm 23:1-3"
    var display: String {
        let verses = startVerse == endVerse ? "\(startVerse)" : "\(startVerse)-\(endVerse)"
        return "\(Self.singular(book)) \(chapter):\(verses)"
    }

    /// How the reference is read aloud: "First John, chapter 1, verse 9"
    var spoken: String {
        var name = Self.singular(book)
        for (digit, word) in [("1 ", "First "), ("2 ", "Second "), ("3 ", "Third ")] where name.hasPrefix(digit) {
            name = word + String(name.dropFirst(digit.count))
        }
        let verses = startVerse == endVerse ? "verse \(startVerse)" : "verses \(startVerse) through \(endVerse)"
        return "\(name), chapter \(chapter), \(verses)"
    }

    private static func singular(_ book: String) -> String {
        book == "Psalms" ? "Psalm" : book
    }
}

/// The World English Bible (public domain), bundled with the app so it works offline.
final class Bible: Sendable {
    static let shared = Bible()

    let books: [BibleBook]

    private init() {
        guard let url = Bundle.main.url(forResource: "web", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let books = try? JSONDecoder().decode([BibleBook].self, from: data) else {
            assertionFailure("web.json is missing from the app bundle")
            books = []
            return
        }
        self.books = books
    }

    func book(named name: String) -> BibleBook? {
        books.first { $0.name == name }
    }

    /// The text of a reference, with several verses joined together. Nil if the reference doesn't exist.
    func text(for reference: VerseReference) -> String? {
        guard let book = book(named: reference.book),
              (1...book.chapters.count).contains(reference.chapter) else { return nil }
        let verses = book.chapters[reference.chapter - 1]
        guard reference.startVerse >= 1,
              reference.endVerse >= reference.startVerse,
              reference.endVerse <= verses.count else { return nil }
        let text = verses[(reference.startVerse - 1)...(reference.endVerse - 1)]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return text.isEmpty ? nil : text
    }

    /// Understands typed or spoken references like "John 3:16", "1 John 1:9", "first john 1 9",
    /// "Psalm 23:1-3" and "Romans 8 28 to 30". Returns nil unless the verse exists.
    func parse(_ input: String) -> VerseReference? {
        // Speech recognition often adds a period at the end.
        var text = input.lowercased().trimmingCharacters(in: .punctuationCharacters.union(.whitespaces))
        for (word, digit) in [("first ", "1 "), ("second ", "2 "), ("third ", "3 "), ("1st ", "1 "), ("2nd ", "2 "), ("3rd ", "3 ")]
        where text.hasPrefix(word) {
            text = digit + String(text.dropFirst(word.count))
        }
        for word in ["chapter", "verses", "verse"] {
            text = text.replacingOccurrences(of: word, with: " ")
        }

        let pattern = #/^\s*((?:[1-3]\s*)?[a-z][a-z .]*?)\s*(\d+)\s*[:.,\s]\s*(\d+)(?:\s*(?:-|–|to|through)\s*(\d+))?\s*$/#
        guard let match = text.wholeMatch(of: pattern),
              let book = findBook(String(match.1)),
              let chapter = Int(match.2),
              let start = Int(match.3) else { return nil }
        let end = match.4.flatMap { Int($0) } ?? start

        let reference = VerseReference(book: book.name, chapter: chapter, startVerse: start, endVerse: end)
        return self.text(for: reference) == nil ? nil : reference
    }

    private func findBook(_ name: String) -> BibleBook? {
        let key = Self.squash(name)
        let aliases = ["psalm": "Psalms", "songofsongs": "Song of Solomon", "revelations": "Revelation"]
        if let alias = aliases[key] { return book(named: alias) }
        return books.first { Self.squash($0.name) == key }
            ?? books.first { key.count >= 3 && Self.squash($0.name).hasPrefix(key) }
    }

    private static func squash(_ name: String) -> String {
        name.lowercased().filter { $0.isLetter || $0.isNumber }
    }
}
