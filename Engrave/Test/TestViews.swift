import SwiftUI

struct TestRunView: View {
    let verses: [MemoryVerse]
    @AppStorage("answerMode") private var mode: AnswerMode = .voice
    @State private var session: TestSession?

    var body: some View {
        Group {
            if let session {
                TestRunningView(session: session, restart: start)
            } else {
                StartPanel(
                    title: verses.count == 1 ? verses[0].reference.display : "\(verses.count) Verses",
                    detail: "I'll read the reference. You recite the verse from memory.",
                    systemImage: "checkmark.seal",
                    mode: $mode,
                    start: start
                )
            }
        }
        .crossBackground()
        .navigationTitle("Test")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { session?.stop() }
    }

    private func start() {
        session?.stop()
        let new = TestSession(verses: verses, mode: mode)
        session = new
        Task { await new.run() }
    }
}

struct TestRunningView: View {
    let session: TestSession
    let restart: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                switch session.phase {
                case .finished:
                    summary
                case .stopped:
                    DoneView(title: "Paused", message: "I didn't hear an answer, so I stopped.", againLabel: "Start Over", again: restart)
                default:
                    running
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private var running: some View {
        if session.verses.count > 1 {
            VStack(spacing: 8) {
                ProgressView(value: Double(session.index), total: Double(session.verses.count))
                Text("Verse \(min(session.index + 1, session.verses.count)) of \(session.verses.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }

        if let verse = session.current {
            Text(verse.reference.display)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
        }

        switch session.phase {
        case .answering:
            Text(session.conversation.mode == .typing ? "Type the verse from memory" : "Say the verse")
                .font(.title3)
                .foregroundStyle(.secondary)
        case .checking:
            ProgressView()
        case .result:
            if let grade = session.lastGrade { GradeCard(grade: grade) }
        default:
            EmptyView()
        }

        AnswerArea(conversation: session.conversation, placeholder: "Type the verse")
    }

    private var summary: some View {
        let passed = session.results.filter(\.grade.passed).count
        return VStack(spacing: 16) {
            DoneView(
                title: "\(passed) of \(session.results.count) correct",
                message: passed == session.results.count ? "Every verse word for word." : "Practice the ones you missed and try again.",
                againLabel: "Test Again",
                again: restart
            )
            ForEach(session.results) { result in
                HStack {
                    Image(systemName: result.grade.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(result.grade.passed ? .green : .orange)
                    Text(result.reference)
                    Spacer()
                    Text("\(Int((result.grade.score * 100).rounded()))%").foregroundStyle(.secondary)
                }
            }
        }
    }
}
