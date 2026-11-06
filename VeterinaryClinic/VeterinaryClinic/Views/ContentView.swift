import SwiftUI

struct ContentView: View {
    @StateObject private var manager = ClinicManager(sample: true)

    var body: some View {
        TabView {
            AppointmentsView()
                .tabItem { Label("Appointments", systemImage: "calendar") }
            ChargesView()
                .tabItem { Label("Charges", systemImage: "banknote.fill") }
        }
        .environmentObject(manager)
        .tint(Theme.appointments)
    }
}

#Preview {
    ContentView()
}
