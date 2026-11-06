import SwiftUI

struct BillingView: View {
    @EnvironmentObject var manager: MembershipManager

    var body: some View {
        let paidCount = manager.memberships.filter { $0.outstanding == 0 }.count

        NavigationStack {
            VStack(spacing: 12) {
                SummaryBanner(icon: "creditcard.fill",
                              title: "Outstanding balance",
                              subtitle: "\(paidCount)/\(manager.memberships.count) fully paid · charges \(manager.totalEstimated.vnd)",
                              value: String(format: "%.2f", manager.totalOutstanding / 1_000_000),
                              valueLabel: "million VND",
                              color: Theme.billing,
                              customBackgroundColor: .white.opacity(0.85)
                )

                List {
                    ForEach(manager.memberships) { m in
                        NavigationLink {
                            MemberDetailView(membershipID: m.id)
                        } label: {
                            BillCard(membership: m)
                        }
                        .listRowCard()
                    }
                }
                .listStyle(.plain)
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                TopBar(title: "BILLING", glassTint: Theme.billing.opacity(0.9), topPadding: 20, bottomPadding: 12) {
                    RolePicker(color: Theme.billing)
                }
            }
            .screenBackground("billView", fit: true, topOffset: 210)
        }
    }
}

// MARK: - Bill card (ước tính phí theo từng loại gói)
struct BillCard: View {
    let membership: Membership

    var body: some View {
        let color = Theme.color(for: membership.type)
        let b = membership.breakdown
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(membership.memberName).font(.headline)
                    HStack(spacing: 6) {
                        IDChip(text: membership.id, color: color)
                        Text(membership.typeName).font(.system(size: 12)).foregroundColor(.gray)
                    }
                }
                Spacer()
                StatusPill(text: membership.status.rawValue, color: Theme.color(for: membership.status))
            }
            Divider()
            ForEach(b.lines) { l in InfoRow(label: l.label, value: l.amount.vnd) }
            if let p = b.promotion {
                InfoRow(label: "Promotion \(p.code) (−\(Int(p.percentOff))%)", value: "−" + b.discount.vnd)
            }
            Divider()
            InfoRow(label: "Total", value: b.total.vnd)
            InfoRow(label: "Paid", value: b.paid.vnd)
            HStack {
                Text("OUTSTANDING").font(.system(size: 10, weight: .semibold)).foregroundColor(.gray)
                Spacer()
                Text(b.outstanding.vnd)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(b.outstanding == 0 ? Theme.success : Theme.billing)
            }
        }
    }
}

#Preview {
    BillingView().environmentObject(MembershipManager.preview())
}
