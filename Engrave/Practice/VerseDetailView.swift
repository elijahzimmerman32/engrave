import SwiftUI

struct VerseDetailView: View {
    let verse: MemoryVerse
    @State private var textHidden = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(verse.text)
                    .font(.title3)
                    .blur(radius: textHidden ? 10 : 0)
                    .onTapGesture { textHidden.toggle() }
                    .accessibilityHint("Tap to hide or show the verse")

                VStack(spacing: 12) {
                    Button {
                        Task { await Speaker.shared.speak(verse.text) }
                    } label: {
                        Label("Listen", systemImage: "speaker.wave.2.fill").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    NavigationLink {
                        PracticeView(verse: verse)
                    } label: {
                        Label("Practice & Test", systemImage: "square.stack.3d.up").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    NavigationLink {
                        TestRunView(verses: [verse])
                    } label: {
                        Label("Test Only", systemImage: "checkmark.seal").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .controlSize(.large)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Progress").font(.headline)
                    Text("Practiced \(verse.practiceCount) \(verse.practiceCount == 1 ? "time" : "times")")
                    Text("Tested \(verse.testAttempts) \(verse.testAttempts == 1 ? "time" : "times"), best \(Int((verse.bestScore * 100).rounded()))%")
                    if let mastered = verse.masteredAt {
                        Text("Memorized \(mastered.formatted(date: .abbreviated, time: .omitted))")
                            .foregroundStyle(.tint)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle(verse.reference.display)
        .toolbar {
            Button(textHidden ? "Show Text" : "Hide Text", systemImage: textHidden ? "eye" : "eye.slash") {
                textHidden.toggle()
            }
        }
        .onDisappear { Speaker.shared.stop() }
    }
}
