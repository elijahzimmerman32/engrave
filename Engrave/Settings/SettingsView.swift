import SwiftUI
import AVFoundation

struct SettingsView: View {
    @AppStorage(AppSettings.voiceKey) private var voiceID = ""
    @AppStorage(AppSettings.repeatsKey) private var repeats = 2
    @AppStorage(AppSettings.styleKey) private var style: PracticeStyle = .pieces

    private let voices = Voices.english

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Voice", selection: $voiceID) {
                        ForEach(voices, id: \.identifier) { voice in
                            Text(Voices.label(for: voice)).tag(voice.identifier)
                        }
                    }
                    Button("Hear This Voice", systemImage: "speaker.wave.2.fill") {
                        Task { await Speaker.shared.speak("I have hidden your word in my heart, that I might not sin against you.", slow: true) }
                    }
                } header: {
                    Text("Voice")
                } footer: {
                    Text("For the most natural voices, download an Enhanced or Premium voice like Evan or Nathan in your iPhone's Settings app: Accessibility, then Spoken Content, then Voices, then English. It will show up here once it's downloaded.")
                }

                Section {
                    Picker("Style", selection: $style) {
                        ForEach(PracticeStyle.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    Text(style.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Practice style")
                }

                Section {
                    Picker("Say each round", selection: $repeats) {
                        Text("Once").tag(1)
                        Text("Twice").tag(2)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Repeats")
                } footer: {
                    Text("How many times in a row you need to get each round right before moving on.")
                }
            }
            .crossBackground()
            .navigationTitle("Settings")
            .onAppear {
                // Show the voice actually in use when nothing has been picked yet.
                if voiceID.isEmpty || !voices.contains(where: { $0.identifier == voiceID }) {
                    voiceID = Voices.current?.identifier ?? ""
                }
            }
            .onDisappear { Speaker.shared.stop() }
        }
    }
}
