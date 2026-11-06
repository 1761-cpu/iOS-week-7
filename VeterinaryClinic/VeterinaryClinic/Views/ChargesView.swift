import SwiftUI

struct ChargesView: View {
    @EnvironmentObject var manager: ClinicManager

    var body: some View {
        let list = manager.search("", type: nil)

        NavigationStack {
            VStack(spacing: 12) {
                SummaryBanner(icon: "banknote.fill",
                              title: "Estimated charges",
                              subtitle: "\(manager.lockedCount)/\(manager.appointments.count) locked · \(manager.totalEstimated.vnd)",
                              value: String(format: "%.2f", manager.totalEstimated / 1_000_000),
                              valueLabel: "million VND",
                              color: Theme.charges,
                              customBackgroundColor: .white.opacity(0.85)
                )

                List {
                    ForEach(list) { a in
                        NavigationLink {
                            AppointmentDetailView(appointmentID: a.id)
                        } label: {
                            ChargeCard(appointment: a)
                        }
                        .listRowCard()
                    }
                }
                .listStyle(.plain)
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                TopBar(title: "CHARGES", glassTint: Theme.charges.opacity(0.9), topPadding: 20, bottomPadding: 12) {
                    RolePicker(color: Theme.charges)
                }
            }
            .screenBackground("chargeView", fit: true, topOffset: 220)
        }
    }
}

// MARK: - Charge card (ước tính phí theo từng loại lịch hẹn)
struct ChargeCard: View {
    let appointment: Appointment

    var body: some View {
        let a = appointment
        let color = Theme.color(for: a.type)
        let b = a.breakdown
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(a.pet.name) · \(a.owner.name)").font(.headline)
                    HStack(spacing: 6) {
                        IDChip(text: a.id, color: color)
                        Text(a.typeName).font(.system(size: 12)).foregroundColor(.gray)
                    }
                }
                Spacer()
                StatusPill(text: a.status.rawValue, color: Theme.color(for: a.status))
            }
            Divider()
            ForEach(b.lines) { l in InfoRow(label: l.label, value: l.amount.vnd) }
            if let p = b.promotion {
                InfoRow(label: "Promotion \(p.code) (−\(Int(p.percentOff))%)", value: "−" + b.discount.vnd)
            }
            Divider()
            HStack {
                Text(a.status == .cancelled ? "CANCELLED" : "TOTAL").font(.system(size: 10, weight: .semibold)).foregroundColor(.gray)
                Spacer()
                Text(a.estimatedCharges.vnd)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(a.status == .cancelled ? .gray : Theme.charges)
            }
        }
    }
}

#Preview {
    ChargesView().environmentObject(ClinicManager.preview())
}
