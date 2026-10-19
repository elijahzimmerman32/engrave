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

/// Shown when the app opens: the cross fades in, then the whole screen fades into the app.
struct SplashView: View {
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 24) {
                CrossMark()
                    .foregroundStyle(.tint)
                    .frame(height: 160)
                    .scaleEffect(appeared ? 1 : 0.85)
                Text("Engrave")
                    .font(.largeTitle.weight(.semibold))
                    .fontDesign(.serif)
            }
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) { appeared = true }
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
