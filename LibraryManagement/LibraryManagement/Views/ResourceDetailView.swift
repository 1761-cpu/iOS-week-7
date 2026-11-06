import SwiftUI

struct ResourceDetailView: View {
    @EnvironmentObject var manager: LibraryManager
    let resourceID: String
    @State private var returnDate = Date()
    @State private var message: String?

    var body: some View {
        Group {
            if let r = manager.resource(withID: resourceID) {
                content(r)
            } else {
                EmptyHint(systemImage: "questionmark.folder", text: "Resource not found.")
            }
        }
        .navigationTitle("DETAILS")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { MemberPicker() } }
        .messageAlert("Result", message: $message)
    }

    private func content(_ r: LibraryResource) -> some View {
        let color = Theme.color(for: r.category)
        let member = manager.currentMember
        let myLoan = r.loans.first { $0.memberID == manager.currentMemberID }

        return List {
            // Header
            Section {
                HStack(spacing: 12) {
                    IconBadge(systemName: r.icon, color: color)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(r.title).font(.headline)
                        IDChip(text: r.id, color: color)
                    }
                }
                HStack {
                    Text("Status").foregroundColor(.gray)
                    Spacer()
                    StatusPill(text: r.availabilityText, color: Theme.statusColor(for: r))
                }
            }

            // Thông tin riêng của từng loại (polymorphism: detailRows)
            Section {
                ForEach(r.detailRows) { InfoRow(label: $0.label, value: $0.value) }
            } header: {
                SectionTag("Information", systemImage: "info.circle.fill", color: color)
            }

            // Chính sách & phí (polymorphism: depositAmount / accessFee / lateFeePerDay)
            Section {
                InfoRow(label: "Loan period",
                        value: member.map { "\(r.loanDays(for: $0)) days (\($0.role.rawValue))" } ?? "—")
                InfoRow(label: "Refundable deposit", value: r.depositAmount.vnd)
                InfoRow(label: "Access fee", value: r.accessFee.vnd)
                InfoRow(label: "Late fee / day", value: r.lateFeePerDay.vnd)
            } header: {
                SectionTag("Policy & Fees", systemImage: "banknote.fill", color: color)
            }

            // Borrow / Access
            Section {
                Button {
                    borrow(r)
                } label: {
                    Label("\(r.actionVerb) as \(member?.name ?? "—")", systemImage: "arrow.down.circle.fill")
                        .bold()
                }
                .foregroundColor(color)
            } header: {
                SectionTag(r.actionVerb, systemImage: "hand.tap.fill", color: color)
            }

            // Return (chỉ hiện khi thành viên hiện tại đang mượn)
            if let loan = myLoan {
                Section {
                    InfoRow(label: "Borrowed on", value: loan.borrowDate.short)
                    InfoRow(label: "Due date", value: loan.dueDate.short)
                    DatePicker("Simulated return date", selection: $returnDate, displayedComponents: .date)
                        .font(.system(size: 14))
                    let late = r.lateDays(for: loan, on: returnDate)
                    InfoRow(label: "Late days", value: "\(late)")
                    InfoRow(label: "Estimated late fee", value: r.calculateLateFee(daysLate: late).vnd)
                    Button {
                        giveBack(r)
                    } label: {
                        Label(r.returnVerb, systemImage: "arrow.uturn.backward.circle.fill").bold()
                    }
                    .foregroundColor(Theme.loans)
                } header: {
                    SectionTag(r.returnVerb, systemImage: "checkmark.seal.fill", color: Theme.loans)
                }
            }

            // Active loans
            Section {
                if r.loans.isEmpty {
                    Text("No active loans.").foregroundColor(.gray)
                }
                ForEach(r.loans) { l in
                    HStack {
                        Text(manager.member(withID: l.memberID)?.name ?? l.memberID)
                        Spacer()
                        Text("Due \(l.dueDate.short)")
                            .font(.caption)
                            .foregroundColor(r.isOverdue(l) ? Theme.danger : .gray)
                    }
                }
            } header: {
                SectionTag("Current users", systemImage: "person.2.fill", color: .gray)
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Actions
    private func borrow(_ r: LibraryResource) {
        do {
            let loan = try manager.borrow(resourceID: r.id, memberID: manager.currentMemberID)
            var lines = ["\(r.actionVerb) successful.", "Due date: \(loan.dueDate.short)"]
            if loan.depositPaid > 0 { lines.append("Deposit charged: \(loan.depositPaid.vnd) (refundable)") }
            if loan.accessFeePaid > 0 { lines.append("Access fee charged: \(loan.accessFeePaid.vnd)") }
            message = lines.joined(separator: "\n")
        } catch {
            message = "Rejected: " + error.localizedDescription
        }
    }

    private func giveBack(_ r: LibraryResource) {
        do {
            let rc = try manager.giveBack(resourceID: r.id, memberID: manager.currentMemberID, on: returnDate)
            var lines = ["\(r.returnVerb) successful."]
            lines.append("Late days: \(rc.lateDays) — late fee: \(rc.lateFee.vnd)")
            if rc.depositRefunded > 0 { lines.append("Deposit refunded: \(rc.depositRefunded.vnd)") }
            if rc.amountDue > 0 { lines.append("Amount to pay: \(rc.amountDue.vnd)") }
            message = lines.joined(separator: "\n")
        } catch {
            message = "Rejected: " + error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack { ResourceDetailView(resourceID: "B002") }
        .environmentObject(LibraryManager.preview())
}
