import SwiftUI
import WebKit

/// Bible Cross-References by Oleksii Trekhleb (trekhleb.dev), which draws the Bible's
/// 344,799 cross-references as arcs. It's a website, so this tab needs an internet connection.
struct ConnectionsView: View {
    static let home = URL(string: "https://trekhleb.dev/bible-cross-references/")!

    @Environment(AppNavigator.self) private var navigator

    var body: some View {
        NavigationStack {
            WebPageView(url: navigator.connectionsURL, request: navigator.connectionsRequest)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle("Connections")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    Button("Start Over", systemImage: "arrow.counterclockwise") {
                        navigator.openConnections(Self.home)
                    }
                }
        }
    }

    /// Opens the site focused on a verse, e.g. ?ref=John.3.16
    static func url(for reference: VerseReference) -> URL {
        guard let code = osisCodes[reference.book] else { return home }
        var components = URLComponents(url: home, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "ref", value: "\(code).\(reference.chapter).\(reference.startVerse)")]
        return components.url ?? home
    }

    /// The standard (OSIS) short names for each book, which the site uses in its links.
    private static let osisCodes: [String: String] = {
        let names = ["Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy", "Joshua", "Judges", "Ruth", "1 Samuel", "2 Samuel", "1 Kings", "2 Kings", "1 Chronicles", "2 Chronicles", "Ezra", "Nehemiah", "Esther", "Job", "Psalms", "Proverbs", "Ecclesiastes", "Song of Solomon", "Isaiah", "Jeremiah", "Lamentations", "Ezekiel", "Daniel", "Hosea", "Joel", "Amos", "Obadiah", "Jonah", "Micah", "Nahum", "Habakkuk", "Zephaniah", "Haggai", "Zechariah", "Malachi", "Matthew", "Mark", "Luke", "John", "Acts", "Romans", "1 Corinthians", "2 Corinthians", "Galatians", "Ephesians", "Philippians", "Colossians", "1 Thessalonians", "2 Thessalonians", "1 Timothy", "2 Timothy", "Titus", "Philemon", "Hebrews", "James", "1 Peter", "2 Peter", "1 John", "2 John", "3 John", "Jude", "Revelation"]
        let codes = ["Gen", "Exod", "Lev", "Num", "Deut", "Josh", "Judg", "Ruth", "1Sam", "2Sam", "1Kgs", "2Kgs", "1Chr", "2Chr", "Ezra", "Neh", "Esth", "Job", "Ps", "Prov", "Eccl", "Song", "Isa", "Jer", "Lam", "Ezek", "Dan", "Hos", "Joel", "Amos", "Obad", "Jonah", "Mic", "Nah", "Hab", "Zeph", "Hag", "Zech", "Mal", "Matt", "Mark", "Luke", "John", "Acts", "Rom", "1Cor", "2Cor", "Gal", "Eph", "Phil", "Col", "1Thess", "2Thess", "1Tim", "2Tim", "Titus", "Phlm", "Heb", "Jas", "1Pet", "2Pet", "1John", "2John", "3John", "Jude", "Rev"]
        return Dictionary(uniqueKeysWithValues: zip(names, codes))
    }()
}

private struct WebPageView: UIViewRepresentable {
    let url: URL
    let request: Int

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.allowsBackForwardNavigationGestures = true
        webView.load(URLRequest(url: url))
        context.coordinator.request = request
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.request != request else { return }
        context.coordinator.request = request
        webView.load(URLRequest(url: url))
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var request = -1
    }
}
