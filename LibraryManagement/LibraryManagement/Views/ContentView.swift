import SwiftUI

struct ContentView: View {
    @StateObject private var manager = LibraryManager(sample: true)

    var body: some View {
        TabView {
            ResourcesView()
                .tabItem { Label("Resources", systemImage: "books.vertical.fill") }
            LoansView()
                .tabItem { Label("My Loans", systemImage: "checklist") }
        }
        .environmentObject(manager)
        .tint(Theme.journal)
    }
}

#Preview {
    ContentView()
}
