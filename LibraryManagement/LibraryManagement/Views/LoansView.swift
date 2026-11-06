import SwiftUI

struct LoansView: View {
    @EnvironmentObject var manager: LibraryManager

    var body: some View {
        let items = manager.loans(ofMember: manager.currentMemberID)
        let member = manager.currentMember

        NavigationStack {
            List {
                if let m = member {
                    HStack {
                        Image(systemName: "person.crop.circle.fill").font(.title2).foregroundColor(Theme.loans)
                        VStack(alignment: .leading) {
                            Text(m.name).foregroundColor(Theme.loans).bold()
                            Text("\(m.role.rawValue) · \(items.count)/\(m.role.borrowLimit) active loans")
                                .font(.caption).foregroundColor(.black)
                        }
                    }
                    .listRowCard(fill: .white)
                }

                if items.isEmpty {
                    EmptyHint(systemImage: "tray", text: "No active loans.").listRowCard()
                }

                ForEach(items, id: \.loan.id) { item in
                    NavigationLink {
                        ResourceDetailView(resourceID: item.resource.id)
                    } label: {
                        LoanCard(resource: item.resource, loan: item.loan)
                    }
                    .listRowCard()
                }
            }
            .listStyle(.plain)
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                TopBar(title: "MY LOANS", glassTint: Theme.loans.opacity(0.9), topPadding: 20, bottomPadding: 20) {
                    MemberPicker(color: Theme.loans)
                }
            }
            .screenBackground("loanView", fit: true, topOffset: 210)
        }
    }
}

struct LoanCard: View {
    let resource: LibraryResource
    let loan: Loan

    var body: some View {
        let color = Theme.color(for: resource.category)
        let late = resource.lateDays(for: loan, on: Date())
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                IconBadge(systemName: resource.icon, color: color, size: 38)
                VStack(alignment: .leading, spacing: 4) {
                    Text(resource.title).font(.headline).lineLimit(2)
                    IDChip(text: resource.id, color: color)
                }
                Spacer()
                if late > 0 {
                    StatusPill(text: "\(late) days late", color: Theme.danger)
                } else {
                    StatusPill(text: "On time", color: Theme.success)
                }
            }
            InfoRow(label: "Due date", value: loan.dueDate.short)
            InfoRow(label: "Deposit paid", value: loan.depositPaid.vnd)
            if late > 0 {
                InfoRow(label: "Late fee so far", value: resource.calculateLateFee(daysLate: late).vnd)
            }
        }
    }
}

#Preview {
    LoansView().environmentObject(LibraryManager.preview())
}
