import SwiftUI

struct PracticeView: View {
    let verse: MemoryVerse
    @AppStorage("answerMode") private var mode: AnswerMode = .voice
    @State private var session: PracticeSession?

    var body: some View {
        Group {
            if let session {
                PracticeRunningView(session: session, restart: start)
            } else {
                StartPanel(
                    title: "Practice in Pieces",
                    detail: "You'll hear the verse, then learn it a phrase at a time, adding one piece each round. At the end you'll be tested on the whole verse.",
                    systemImage: "square.stack.3d.up",
                    mode: $mode,
                    start: start
                )
            }
        }
        .navigationTitle(verse.reference.display)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { session?.stop() }
    }

    private func start() {
        session?.stop()
        let new = PracticeSession(verse: verse, mode: mode)
        session = new
        Task { await new.run() }
    }
}

private struct PracticeRunningView: View {
    let session: PracticeSession
    let restart: () -> Void
    @State private var showHint = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                switch session.phase {
                case .finished:
                    finished
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
    private var finished: some View {
        if let grade = session.finalGrade {
            DoneView(
                title: grade.passed ? "Memorized!" : "Almost there",
                message: grade.passed ? "You said the whole verse from memory." : "Practice it again and you'll have it.",
                againLabel: "Practice Again",
                again: restart
            )
            GradeCard(grade: grade)
        } else {
            DoneView(title: "Verse practiced", message: "Try the test when you're ready.", againLabel: "Practice Again", again: restart)
        }
        NavigationLink {
            TestRunView(verses: [session.verse])
        } label: {
            Text(session.finalGrade == nil ? "Take the Test" : "Test Again").frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    @ViewBuilder
    private var running: some View {
        if session.isFinalTest {
            Text("Test").font(.subheadline.weight(.semibold)).foregroundStyle(.tint)
        } else {
            VStack(spacing: 8) {
                ProgressView(value: Double(session.step), total: Double(session.chunks.count))
                Text("Piece \(min(session.step + 1, session.chunks.count)) of \(session.chunks.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }

        Text(status)
            .font(.title3.weight(.semibold))
            .multilineTextAlignment(.center)

        switch session.phase {
        case .starting:
            Text(session.verse.text).font(.title3)
        case .hearing:
            Text(session.newPiece).font(.title2)
        case .answering where session.isFinalTest:
            Text(session.verse.reference.display).font(.largeTitle.bold())
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
    }

    private var status: String {
        let typing = session.conversation.mode == .typing
        switch session.phase {
        case .starting: return "Listen to the whole verse"
        case .hearing: return session.step == 0 ? "Listen to the first piece" : "Listen to the next piece"
        case .answering:
            if session.isFinalTest { return typing ? "Type the whole verse from memory" : "Say the whole verse from memory" }
            if session.step == 0 { return typing ? "Type that piece" : "Say that piece" }
            return typing ? "Type it from the beginning" : "Say it from the beginning"
        case .checking: return "Checking…"
        case .result: return session.lastGrade?.passed == true ? "Nice!" : "Let's try again"
        case .finished, .stopped: return ""
        }
    }
}
