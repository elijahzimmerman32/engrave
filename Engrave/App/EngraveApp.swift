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

/// Which tab is showing, and where the Connections tab should open.
@MainActor
@Observable
final class AppNavigator {
    enum TabID: Hashable { case verses, connections, settings }

    var tab = TabID.verses
    private(set) var connectionsURL = ConnectionsView.home
    /// Bumped on every request, so the page reloads even when the address is the same.
    private(set) var connectionsRequest = 0

    func showConnections(for reference: VerseReference) {
        openConnections(ConnectionsView.url(for: reference))
        tab = .connections
    }

    func openConnections(_ url: URL) {
        connectionsURL = url
        connectionsRequest += 1
    }
}

struct RootView: View {
    @State private var showSplash = true
    @State private var navigator = AppNavigator()

    var body: some View {
        ZStack {
            tabs
            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .environment(navigator)
        .task {
            // Load the Bible while the cross is showing, so the app is ready when it fades in.
            Task.detached(priority: .userInitiated) { _ = Bible.shared }
            try? await Task.sleep(for: .seconds(SplashView.wordDuration + 0.5))
            withAnimation(.easeInOut(duration: 0.9)) { showSplash = false }
        }
    }

    private var tabs: some View {
        TabView(selection: $navigator.tab) {
            Tab("My Verses", systemImage: "book.closed", value: AppNavigator.TabID.verses) {
                LibraryView()
            }
            Tab("Connections", systemImage: "point.3.connected.trianglepath.dotted", value: AppNavigator.TabID.connections) {
                ConnectionsView()
            }
            Tab("Settings", systemImage: "gearshape", value: AppNavigator.TabID.settings) {
                SettingsView()
            }
        }
    }
}
