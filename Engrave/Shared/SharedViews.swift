import SwiftUI

/// The screen before a practice or test starts, where the person picks how they'll answer.
struct StartPanel: View {
    let title: String
    let detail: String
    let systemImage: String
    @Binding var mode: AnswerMode
    let start: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: systemImage)
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text(title).font(.title2.bold())
            Text(detail)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Picker("Answer by", selection: $mode) {
                ForEach(AnswerMode.allCases) { mode in
                    Label(mode.label, systemImage: mode.icon).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            if mode == .voice {
                Text("Hands-free: I'll talk you through it and listen for your answers. No tapping needed.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: start) {
                Text("Start").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}

struct DoneView: View {
    let title: String
    let message: String
    let againLabel: String
    let again: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text(title).font(.title2.bold())
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button(againLabel, action: again)
                .buttonStyle(.bordered)
        }
        .padding(.top, 40)
    }
}

/// Where the person answers: a live transcript while listening, or a text box when typing.
struct AnswerArea: View {
    let conversation: Conversation
    let placeholder: String
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 12) {
            if conversation.mode == .voice, conversation.listener.isListening {
                Label("Listening…", systemImage: "waveform")
                    .font(.headline)
                    .foregroundStyle(.tint)
                    .symbolEffect(.variableColor.iterative, isActive: true)
                if !conversation.listener.transcript.isEmpty {
                    Text(conversation.listener.transcript)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                Button("I'm Done") { conversation.listener.finish() }
                    .buttonStyle(.bordered)
            }

            if conversation.waitingForTyping {
                TextField(placeholder, text: $text, axis: .vertical)
                    .lineLimit(3...8)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .focused($focused)
                    .onAppear { focused = true }
                Button {
                    conversation.submitTyped(text)
                    text = ""
                } label: {
                    Text("Check").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if conversation.waitingToContinue {
                Button {
                    conversation.continueTapped()
                } label: {
                    Text("Continue").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }
}

/// Shows how an answer went, with missed words in red.
struct GradeCard: View {
    let grade: Grade

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(
                grade.passed ? "Correct" : "Not quite",
                systemImage: grade.passed ? "checkmark.circle.fill" : "arrow.counterclockwise.circle.fill"
            )
            .font(.headline)
            .foregroundStyle(grade.passed ? .green : .orange)

            Text(highlighted)
            Text(grade.feedback)
                .font(.callout)
                .foregroundStyle(.secondary)
            Text("\(Int((grade.score * 100).rounded()))% match")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: .rect(cornerRadius: 16))
    }

    private var highlighted: AttributedString {
        var result = AttributedString()
        for word in grade.words {
            var piece = AttributedString((word.id == 0 ? "" : " ") + word.text)
            if word.status == .missed {
                piece.foregroundColor = Color.red
            }
            result += piece
        }
        return result
    }
}
