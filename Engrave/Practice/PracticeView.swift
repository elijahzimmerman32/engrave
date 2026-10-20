import SwiftUI

/// Learn a verse in pieces, then go straight into a test on it.
struct PracticeView: View {
    let verse: MemoryVerse
    @AppStorage("answerMode") private var mode: AnswerMode = .voice
    @State private var session: PracticeSession?
    @State private var test: TestSession?

    var body: some View {
        Group {
            if let test {
                TestRunningView(session: test, restart: startTest)
            } else if let session {
                PracticeRunningView(session: session, restart: start, takeTest: startTest)
            } else {
                StartPanel(
                    title: "Practice & Test",
                    detail: "You'll hear the verse, then learn it a phrase at a time, adding one piece each round. When you can say it all, I'll test you on it.",
                    systemImage: "square.stack.3d.up",
                    mode: $mode,
                    start: start
                )
            }
        }
        .crossBackground()
        .navigationTitle(verse.reference.display)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            session?.stop()
            test?.stop()
        }
    }

    private func start() {
        session?.stop()
        test?.stop()
        test = nil
        let new = PracticeSession(verse: verse, mode: mode)
        session = new
        Task {
            await new.run()
            // Once the whole verse is learned, carry on into the test with no tap needed.
            if new.phase == .finished, session === new, test == nil {
                startTest()
            }
        }
    }

    private func startTest() {
        session?.stop()
        test?.stop()
        let new = TestSession(verses: [verse], mode: mode)
        test = new
        Task { await new.run() }
    }
}

private struct PracticeRunningView: View {
    let session: PracticeSession
    let restart: () -> Void
    let takeTest: () -> Void
    @State private var showHint = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                switch session.phase {
                case .finished:
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.tint)
                        Text("Verse practiced").font(.title2.bold())
                        Text("Starting your test…").foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)
                case .stopped:
                    DoneView(title: "Paused", message: "I didn't hear an answer, so I stopped.", againLabel: "Start Over", again: restart)
                default:
                    running
                }
            }
            .padding()
        }
        .onChange(of: session.step) { showHint = false }
    }

    @ViewBuilder
    private var running: some View {
        VStack(spacing: 8) {
            ProgressView(value: Double(session.step), total: Double(session.roundCount))
            Text("\(session.isWholeRound ? "Whole verse" : "\(session.style == .buildUp ? "Round" : "Piece") \(min(session.step + 1, session.chunks.count)) of \(session.chunks.count)")  ·  Correct \(session.passesThisStep) of \(session.passesNeeded)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }

        Text(status)
            .font(.title3.weight(.semibold))
            .multilineTextAlignment(.center)

        switch session.phase {
        case .starting:
            Text(session.verse.text).font(.title3)
        case .hearing:
            Text(session.target).font(.title2)
        case .answering:
            Button(showHint ? "Hide Hint" : "Show Hint") { showHint.toggle() }
            if showHint {
                Text(Chunker.firstLetters(session.target))
                    .font(.title3.monospaced())
                    .multilineTextAlignment(.center)
            }
        case .checking:
            ProgressView()
        case .result:
            if let grade = session.lastGrade { GradeCard(grade: grade) }
        case .finished, .stopped:
            EmptyView()
        }

        AnswerArea(conversation: session.conversation, placeholder: "Type it from memory")

        Button("Skip to the Test", action: takeTest)
            .font(.footnote)
    }

    private var status: String {
        let typing = session.conversation.mode == .typing
        switch session.phase {
        case .starting: return "Listen to the whole verse"
        case .hearing:
            if session.isWholeRound { return "Listen to the whole verse" }
            if session.style == .buildUp { return "Listen" }
            return session.step == 0 ? "Listen to the first piece" : "Listen to the next piece"
        case .answering:
            if session.passesThisStep > 0 { return typing ? "Type it once more" : "Say it once more" }
            if session.isWholeRound { return typing ? "Type the whole verse" : "Say the whole verse" }
            if session.style == .buildUp { return typing ? "Type it back" : "Repeat it" }
            return typing ? "Type that piece" : "Say that piece"
        case .checking: return "Checking…"
        case .result:
            guard session.lastGrade?.passed == true else { return "Not quite. Let's try again" }
            return session.passesThisStep > 0 && session.passesThisStep < session.passesNeeded ? "Correct! Once more" : "Correct!"
        case .finished, .stopped: return ""
        }
    }
}
