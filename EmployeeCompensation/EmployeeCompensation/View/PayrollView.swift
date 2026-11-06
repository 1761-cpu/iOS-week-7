import SwiftUI

struct PayrollView: View {
    @EnvironmentObject var manager: PayrollManager
    @State private var message: String?

    var body: some View {
        let month = manager.selectedMonth
        let summaries = manager.summaries(for: month)
        let total = manager.totalPayable(for: month)
        let approved = summaries.filter { $0.isApproved }.count

        NavigationStack {
            VStack(spacing: 12) {
                MonthSwitcher()
                    .padding(12)
                    .background(Theme.cardFill, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)

                SummaryBanner(icon: "banknote.fill",
                              title: "Total payable",
                              subtitle: "\(approved)/\(summaries.count) approved · \(total.vnd)",
                              value: String(format: "%.1f", total / 1_000_000),
                              valueLabel: "million VND",
                              color: Theme.payroll)

                Button {
                    let r = manager.approveAll(month: month)
                    var lines = ["Approved: \(r.approved) payment(s)."]
                    lines += r.errors.map { "• " + $0 }
                    message = lines.joined(separator: "\n")
                } label: {
                    Label("Approve all pending", systemImage: "checkmark.seal.fill")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(Theme.payroll, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)

                List {
                    ForEach(summaries) { s in
                        NavigationLink {
                            EmployeeDetailView(employeeID: s.employeeID)
                        } label: {
                            PayslipCard(summary: s)
                        }
                        .listRowCard()
                    }
                }
                .listStyle(.plain)
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                TopBar(title: "PAYROLL", glassTint: Theme.payroll.opacity(0.9), topPadding: 20, bottomPadding: 12) {
                    RolePicker(color: Theme.payroll)
                }
            }
            .messageAlert("Result", message: $message)
            .screenBackground("payView", fit: true, topOffset: 470)
        }
    }
}

// MARK: - Payslip card (bản tóm tắt lương tháng)
struct PayslipCard: View {
    let summary: PaySummary

    var body: some View {
        let color = Theme.color(for: summary.type)
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(summary.employeeName).font(.headline)
                    HStack(spacing: 6) {
                        IDChip(text: summary.employeeID, color: color)
                        Text(summary.department).font(.system(size: 12)).foregroundColor(.gray)
                    }
                }
                Spacer()
                StatusPill(text: summary.isApproved ? "Approved" : "Pending",
                           color: summary.isApproved ? Theme.success : Theme.warning)
            }
            StatusPill(text: summary.typeName, color: color)
            Divider()
            ForEach(summary.lines) { l in InfoRow(label: l.label, value: l.amount.vnd) }
            ForEach(summary.corrections) { c in
                InfoRow(label: "Correction: \(c.reason)",
                        value: (c.adjustment >= 0 ? "+" : "−") + abs(c.adjustment).vnd)
            }
            Divider()
            HStack {
                Text("NET PAYABLE").font(.system(size: 10, weight: .semibold)).foregroundColor(.gray)
                Spacer()
                Text(summary.netPayable.vnd)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.payroll)
            }
        }
    }
}

#Preview {
    PayrollView().environmentObject(PayrollManager.preview())
}
