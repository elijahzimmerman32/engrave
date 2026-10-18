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
    var body: some View {
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
