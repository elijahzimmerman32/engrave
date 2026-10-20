import SwiftUI

/// A plain Latin cross, sized by its height.
struct CrossMark: View {
    var body: some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            let thickness = height * 0.14
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: thickness * 0.2)
                    .frame(width: thickness, height: height)
                RoundedRectangle(cornerRadius: thickness * 0.2)
                    .frame(width: height * 0.62, height: thickness)
                    .offset(y: height * 0.24)
            }
            .frame(width: geometry.size.width, height: height)
        }
        .aspectRatio(0.62, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

/// Shown when the app opens: the cross fades in with "Hidden" on it and Psalm 119:11 below.
/// The word fades out first, then the whole screen fades into the app.
struct SplashView: View {
    /// How long until the word fades. RootView fades the whole screen shortly after.
    static let wordDuration = 1.8

    @State private var appeared = false
    @State private var wordVisible = true

    private let crossHeight: CGFloat = 320

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            CrossMark()
                .foregroundStyle(.tint)
                .frame(height: crossHeight)
                .overlay(alignment: .top) {
                    // Sits on the crossbar, which starts 24% down the cross and is 14% tall.
                    Text("Hidden")
                        .font(.system(size: crossHeight * 0.09, weight: .semibold, design: .serif))
                        .tracking(1)
                        .foregroundStyle(.white)
                        .frame(height: crossHeight * 0.14)
                        .offset(y: crossHeight * 0.24)
                        .opacity(wordVisible ? 1 : 0)
                }
                .scaleEffect(appeared ? 1 : 0.9)
                .opacity(appeared ? 1 : 0)

            VStack(spacing: 6) {
                Spacer()
                Text("“I have hidden your word in my heart, that I might not sin against you.”")
                    .font(.callout.italic())
                    .fontDesign(.serif)
                    .multilineTextAlignment(.center)
                Text("Psalm 119:11")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 24)
            .opacity(appeared ? 1 : 0)
        }
        .task {
            withAnimation(.easeOut(duration: 0.8)) { appeared = true }
            try? await Task.sleep(for: .seconds(Self.wordDuration))
            withAnimation(.easeInOut(duration: 0.5)) { wordVisible = false }
        }
    }
}

/// A faint cross behind each screen's content.
struct CrossBackdrop: View {
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
            CrossMark()
                .foregroundStyle(.tint.opacity(0.08))
                .frame(height: 440)
                .offset(y: 40)
        }
        .ignoresSafeArea()
    }
}

extension View {
    /// Swaps a screen's plain background for the cross backdrop.
    func crossBackground() -> some View {
        scrollContentBackground(.hidden)
            .background { CrossBackdrop() }
    }
}
