import Foundation

/// Compares a recitation to the verse word by word, forgiving punctuation, capitals,
/// numbers said as digits, and small misspellings.
enum TextMatcher {
    private static let fillers: Set<String> = ["um", "uh", "er", "erm", "hmm"]

    private static let spellOut: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        formatter.locale = Locale(identifier: "en-US")
        return formatter
    }()

    static func compare(expected: String, answer: String) -> Grade {
        let verseWords = splitWords(expected)
            .map { (display: $0, token: normalize($0)) }
            .filter { !$0.token.isEmpty }
        let target = verseWords.map(\.token)
        let said = splitWords(answer)
            .map(normalize)
            .filter { !$0.isEmpty && !fillers.contains($0) }

        let (matchedTarget, matchedSaid) = alignment(target, said)
        let words = verseWords.enumerated().map { index, word in
            Grade.Word(id: index, text: word.display, status: matchedTarget.contains(index) ? .correct : .missed)
        }
        let extra = said.indices.filter { !matchedSaid.contains($0) }.map { said[$0] }
        let score = target.isEmpty ? 0 : Double(matchedTarget.count) / Double(max(target.count, said.count))
        let passed = score >= Grader.passMark

        return Grade(
            score: score,
            words: words,
            extraWords: extra,
            passed: passed,
            feedback: feedback(passed: passed, score: score, words: words, saidAnything: !said.isEmpty)
        )
    }

    private static func feedback(passed: Bool, score: Double, words: [Grade.Word], saidAnything: Bool) -> String {
        let missed = words.filter { $0.status == .missed }.map { normalizeForSpeech($0.text) }
        if !saidAnything { return "I didn't catch anything." }
        if score >= 0.999 { return "Perfect, word for word." }
        if passed { return missed.isEmpty ? "Nearly perfect." : "Nearly perfect. Watch the word \(missed[0])." }
        let correct = words.count - missed.count
        let sample = missed.prefix(4).joined(separator: ", ")
        return "You had \(correct) of \(words.count) words. You missed \(sample)\(missed.count > 4 ? ", and a few more" : "")."
    }

    private static func splitWords(_ text: String) -> [String] {
        text.replacingOccurrences(of: "—", with: " ")
            .replacingOccurrences(of: "–", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
    }

    /// "Lord’s," becomes "lords" and "16" becomes "sixteen".
    static func normalize(_ word: String) -> String {
        let folded = word.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        if let number = Int(folded.filter(\.isNumber)), folded.allSatisfy({ $0.isNumber || $0.isPunctuation }),
           let spelled = spellOut.string(from: NSNumber(value: number)) {
            return spelled.filter { $0.isLetter }
        }
        return folded.filter { $0.isLetter || $0.isNumber }
    }

    private static func normalizeForSpeech(_ word: String) -> String {
        word.filter { $0.isLetter || $0.isNumber || $0 == "’" || $0 == "'" }
    }

    /// Longest common subsequence, so words count only when said in the right order.
    /// Returns the matched positions in each list.
    private static func alignment(_ a: [String], _ b: [String]) -> (Set<Int>, Set<Int>) {
        guard !a.isEmpty, !b.isEmpty else { return ([], []) }
        var table = Array(repeating: Array(repeating: 0, count: b.count + 1), count: a.count + 1)
        for i in stride(from: a.count - 1, through: 0, by: -1) {
            for j in stride(from: b.count - 1, through: 0, by: -1) {
                table[i][j] = similar(a[i], b[j]) ? table[i + 1][j + 1] + 1 : max(table[i + 1][j], table[i][j + 1])
            }
        }
        var matchedA = Set<Int>(), matchedB = Set<Int>()
        var i = 0, j = 0
        while i < a.count && j < b.count {
            if similar(a[i], b[j]) && table[i][j] == table[i + 1][j + 1] + 1 {
                matchedA.insert(i)
                matchedB.insert(j)
                i += 1
                j += 1
            } else if table[i + 1][j] >= table[i][j + 1] {
                i += 1
            } else {
                j += 1
            }
        }
        return (matchedA, matchedB)
    }

    /// Exact match, or close enough to be a recognition slip on a longer word.
    private static func similar(_ a: String, _ b: String) -> Bool {
        if a == b { return true }
        let length = max(a.count, b.count)
        guard length >= 4, abs(a.count - b.count) <= 2 else { return false }
        return editDistance(Array(a), Array(b)) <= (length >= 8 ? 2 : 1)
    }

    private static func editDistance(_ a: [Character], _ b: [Character]) -> Int {
        var previous = Array(0...b.count)
        for i in 1...a.count {
            var current = [i] + Array(repeating: 0, count: b.count)
            for j in 1...b.count {
                current[j] = min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1))
            }
            previous = current
        }
        return previous[b.count]
    }
}
