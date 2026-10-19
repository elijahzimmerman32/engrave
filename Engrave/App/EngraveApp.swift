import SwiftUI
import SwiftData

@main
struct EngraveApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: MemoryVerse.self)
    }
}

struct RootView: View {
    @State private var showSplash = true

    var body: some View {
        ZStack {
            tabs
            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            // Load the Bible while the cross is showing, so the app is ready when it fades in.
            Task.detached(priority: .userInitiated) { _ = Bible.shared }
            try? await Task.sleep(for: .seconds(1.8))
            withAnimation(.easeInOut(duration: 0.9)) { showSplash = false }
        }
    }

    private var tabs: some View {
        TabView {
            Tab("Practice", systemImage: "square.stack.3d.up") {
                PracticeHomeView()
            }
            Tab("My Verses", systemImage: "book.closed") {
                LibraryView()
            }
            Tab("Test", systemImage: "checkmark.seal") {
                TestHomeView()
            }
        }
    }
}
