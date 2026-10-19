import SwiftUI
import SwiftData

/// Choose a verse by typing or saying a reference ("John 3:16"), or by picking from lists.
struct AddVerseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var typed = ""
    @State private var bookName = "John"
    @State private var chapter = 3
    @State private var startVerse = 16
    @State private var endVerse = 16
    @State private var listener = Listener()

    private let bible = Bible.shared

    private var reference: VerseReference? {
        if !typed.trimmingCharacters(in: .whitespaces).isEmpty {
            return bible.parse(typed)
        }
        return VerseReference(book: bookName, chapter: chapter, startVerse: startVerse, endVerse: max(endVerse, startVerse))
    }

    private var verseText: String? {
        reference.flatMap { bible.text(for: $0) }
    }

    private var chapterCount: Int { bible.book(named: bookName)?.chapters.count ?? 1 }

    private var verseCount: Int {
        guard let chapters = bible.book(named: bookName)?.chapters, chapter <= chapters.count else { return 1 }
        return chapters[chapter - 1].count
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField("John 3:16 or Psalm 23:1-3", text: $typed)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                        Button {
                            Task { await listenForReference() }
                        } label: {
                            Image(systemName: listener.isListening ? "waveform" : "mic.fill")
                                .symbolEffect(.variableColor.iterative, isActive: listener.isListening)
                        }
                        .accessibilityLabel("Say a reference")
                    }
                } header: {
                    Text("Type or say a reference")
                }

                if typed.trimmingCharacters(in: .whitespaces).isEmpty {
                    Section("Or pick one") {
                        Picker("Book", selection: $bookName) {
                            ForEach(bible.books) { Text($0.name).tag($0.name) }
                        }
                        Picker("Chapter", selection: $chapter) {
                            ForEach(1...chapterCount, id: \.self) { Text("\($0)").tag($0) }
                        }
                        Picker("From verse", selection: $startVerse) {
                            ForEach(1...verseCount, id: \.self) { Text("\($0)").tag($0) }
                        }
                        Picker("To verse", selection: $endVerse) {
                            ForEach(min(startVerse, verseCount)...verseCount, id: \.self) { Text("\($0)").tag($0) }
                        }
                    }
                }

                Section("Preview") {
                    if let reference, let verseText {
                        Text(reference.display).font(.headline)
                        Text(verseText)
                    } else {
                        Text("I couldn't find that verse. Try something like John 3:16.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .crossBackground()
            .navigationTitle("Add Verse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add", action: add).disabled(verseText == nil)
                }
            }
            .onChange(of: bookName) {
                chapter = 1
                startVerse = 1
                endVerse = 1
            }
            .onChange(of: chapter) {
                startVerse = 1
                endVerse = 1
            }
            .onChange(of: startVerse) {
                if endVerse < startVerse { endVerse = startVerse }
            }
            .onChange(of: listener.transcript) {
                if listener.isListening { typed = listener.transcript }
            }
            .onDisappear { listener.finish() }
        }
    }

    private func listenForReference() async {
        if listener.isListening {
            listener.finish()
            return
        }
        let said = await listener.listen(hints: bible.books.map(\.name), pause: 1.5)
        if !said.isEmpty { typed = said }
    }

    private func add() {
        guard let reference, let verseText else { return }
        context.insert(MemoryVerse(reference: reference, text: verseText))
        dismiss()
    }
}
