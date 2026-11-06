import SwiftUI

struct ContentView: View {
    @StateObject private var manager = PayrollManager(sample: true)

    var body: some View {
        TabView {
            EmployeesView()
                .tabItem { Label("Employees", systemImage: "person.3.fill") }
            PayrollView()
                .tabItem { Label("Payroll", systemImage: "banknote.fill") }
        }
        .environmentObject(manager)
        .tint(Theme.employees)
    }
}

#Preview {
    ContentView()
}
