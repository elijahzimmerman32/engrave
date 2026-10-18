import SwiftUI
import SwiftData

struct LibraryView: View {
    @Query(sort: \MemoryVerse.addedAt, order: .reverse) private var verses: [MemoryVerse]
    @Environment(\.modelContext) private var context
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(verses) { verse in
                    NavigationLink(value: verse) {
                        VerseRow(verse: verse)
                    }
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
            .navigationTitle("My Verses")
            .navigationDestination(for: MemoryVerse.self) { VerseDetailView(verse: $0) }
            .toolbar {
                Button("Add Verse", systemImage: "plus") { showingAdd = true }
            }
            .sheet(isPresented: $showingAdd) { AddVerseView() }
        }
    }
}

private struct VerseRow: View {
    let verse: MemoryVerse

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(verse.reference.display).font(.headline)
                if verse.isMastered {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(.tint)
                }
            }
            Text(verse.text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 2)
    }
}
