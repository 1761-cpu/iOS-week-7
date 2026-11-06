import SwiftUI

struct EmployeesView: View {
    @EnvironmentObject var manager: PayrollManager
    @State private var searchText = ""
    @State private var filter: EmploymentType? = nil

    var displayed: [Employee] { manager.search(searchText, type: filter) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchField(placeholder: "Search name, ID, department...", text: $searchText)

                Picker("Type", selection: $filter) {
                    Text("All").tag(EmploymentType?.none)
                    ForEach(EmploymentType.allCases) { t in
                        Text(t.rawValue).tag(EmploymentType?.some(t))
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

                RoleBanner()

                List {
                    if displayed.isEmpty {
                        EmptyHint(systemImage: "magnifyingglass", text: "No employees found.").listRowCard()
                    }
                    ForEach(displayed) { e in
                        NavigationLink {
                            EmployeeDetailView(employeeID: e.id)
                        } label: {
                            EmployeeCard(employee: e)
                        }
                        .listRowCard()
                    }
                }
                .listStyle(.plain)
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                TopBar(title: "EMPLOYEES", glassTint: Theme.employees.opacity(0.9), topPadding: 20, bottomPadding: 20) {
                    RolePicker(color: Theme.employees)
                }
            }
            .screenBackground("empView", fit: true, topOffset: 123)
        }
    }
}

// MARK: - Employee card
struct EmployeeCard: View {
    @EnvironmentObject var manager: PayrollManager
    let employee: Employee

    var body: some View {
        let color = Theme.color(for: employee.employmentType)
        let month = manager.selectedMonth
        let approved = employee.isApproved(month)
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                IconBadge(systemName: employee.icon, color: color)
                VStack(alignment: .leading, spacing: 4) {
                    Text(employee.name).font(.headline)
                    HStack(spacing: 6) {
                        IDChip(text: employee.id, color: color)
                        Text(employee.position).font(.system(size: 12)).foregroundColor(.gray).lineLimit(1)
                    }
                }
                Spacer()
            }
            InfoRow(label: "Department", value: employee.department)
            Divider()
            HStack {
                StatusPill(text: employee.typeName, color: color)
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(employee.finalPayable(for: month).vnd)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                    StatusPill(text: approved ? "Approved" : "Pending", color: approved ? Theme.success : Theme.warning)
                }
            }
        }
    }
}

#Preview {
    EmployeesView().environmentObject(PayrollManager.preview())
}
