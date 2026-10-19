import SwiftUI
import SwiftData

enum VerseRoute: Hashable {
    case detail(MemoryVerse)
    case practice(MemoryVerse)
    case test(MemoryVerse)
}

struct LibraryView: View {
    @Query(sort: \MemoryVerse.addedAt, order: .reverse) private var verses: [MemoryVerse]
    @Environment(\.modelContext) private var context
    @State private var showingAdd = false
    @State private var path: [VerseRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(verses) { verse in
                    VerseRow(verse: verse) { path.append($0) }
                }
                .onDelete { offsets in
                    for index in offsets { context.delete(verses[index]) }
                }
            }
            .overlay {
                if verses.isEmpty {
                    ContentUnavailableView {
                        Label("No verses yet", systemImage: "book.closed")
                    } description: {
                        Text("Pick a verse you'd like to memorize.")
                    } actions: {
                        Button("Add a Verse") { showingAdd = true }
                            .buttonStyle(.borderedProminent)
                    }
                }
            }
            .crossBackground()
            .navigationTitle("My Verses")
            .navigationDestination(for: VerseRoute.self) { route in
                switch route {
                case .detail(let verse): VerseDetailView(verse: verse)
                case .practice(let verse): PracticeView(verse: verse)
                case .test(let verse): TestRunView(verses: [verse])
                }
            }
            .toolbar {
                Button("Add Verse", systemImage: "plus") { showingAdd = true }
            }
            .sheet(isPresented: $showingAdd) { AddVerseView() }
        }
    }
}

/// A verse with Practice and Test buttons right on it. Tapping the text opens the verse.
private struct VerseRow: View {
    let verse: MemoryVerse
    let open: (VerseRoute) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                open(.detail(verse))
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(verse.reference.display).font(.headline)
                        if verse.isMastered {
                            Image(systemName: "checkmark.seal.fill").foregroundStyle(.tint)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    Text(verse.text)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)

            HStack(spacing: 10) {
                Button {
                    open(.practice(verse))
                } label: {
                    Label("Practice & Test", systemImage: "square.stack.3d.up").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    open(.test(verse))
                } label: {
                    Label("Test", systemImage: "checkmark.seal").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .controlSize(.regular)
        }
        .padding(.vertical, 4)
    }
}
