import SwiftUI
import SwiftData

/// The first tab: pick one of your verses to learn in pieces and then be tested on.
struct PracticeHomeView: View {
    @Query(sort: \MemoryVerse.addedAt, order: .reverse) private var verses: [MemoryVerse]
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            List {
                if !verses.isEmpty {
                    Section {
                        ForEach(verses) { verse in
                            NavigationLink {
                                PracticeView(verse: verse)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(verse.reference.display).font(.headline)
                                        Text(verse.practiceCount == 0 ? "Not practiced yet" : "Practiced \(verse.practiceCount) \(verse.practiceCount == 1 ? "time" : "times")")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if verse.isMastered {
                                        Image(systemName: "checkmark.seal.fill").foregroundStyle(.tint)
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("Pick a verse to learn")
                    } footer: {
                        Text("You'll hear the verse, learn it a piece at a time, then take a test on it.")
                    }
                }
            }
            .overlay {
                if verses.isEmpty {
                    ContentUnavailableView {
                        Label("Nothing to practice yet", systemImage: "square.stack.3d.up")
                    } description: {
                        Text("Add a verse you'd like to memorize, then come back here to learn it.")
                    } actions: {
                        Button("Add a Verse") { showingAdd = true }
                            .buttonStyle(.borderedProminent)
                    }
                }
            }
            .crossBackground()
            .navigationTitle("Practice")
            .toolbar {
                Button("Add Verse", systemImage: "plus") { showingAdd = true }
            }
            .sheet(isPresented: $showingAdd) { AddVerseView() }
        }
    }
}
