import SwiftUI

struct ContentView: View {
    @StateObject private var manager = MembershipManager(sample: true)

    var body: some View {
        TabView {
            MembersView()
                .tabItem { Label("Members", systemImage: "person.3.fill") }
            BillingView()
                .tabItem { Label("Billing", systemImage: "creditcard.fill") }
        }
        .environmentObject(manager)
        .tint(Theme.members)
    }
}

#Preview {
    ContentView()
}
