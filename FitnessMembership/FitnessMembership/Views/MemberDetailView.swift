import SwiftUI

struct MemberDetailView: View {
    @EnvironmentObject var manager: MembershipManager
    let membershipID: String
    @State private var message: String?
    @State private var showEdit = false

    var body: some View {
        Group {
            if let m = manager.membership(withID: membershipID) {
                content(m)
            } else {
                EmptyHint(systemImage: "questionmark.folder", text: "Membership not found.")
            }
        }
        .navigationTitle("Membership")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { RolePicker() } }
        .sheet(isPresented: $showEdit) {
            if let m = manager.membership(withID: membershipID) {
                EditMemberView(membership: m) { message = $0 }.environmentObject(manager)
            }
        }
        .messageAlert("Result", message: $message)
    }

    private func content(_ m: Membership) -> some View {
        let color = Theme.color(for: m.type)
        let b = m.breakdown
        return List {
            // Header
            Section {
                HStack(spacing: 12) {
                    IconBadge(systemName: m.icon, color: color)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(m.memberName).font(.headline)
                        HStack(spacing: 6) {
                            IDChip(text: m.id, color: color)
                            StatusPill(text: m.status.rawValue, color: Theme.color(for: m.status))
                        }
                    }
                }
                HStack {
                    Text("Acting as").foregroundColor(.gray)
                    Spacer()
                    StatusPill(text: manager.currentRole.rawValue, color: Theme.color(for: manager.currentRole))
                }
                .font(.system(size: 13))
            }

            // Thông tin chung
            Section {
                ForEach(m.detailRows) { InfoRow(label: $0.label, value: $0.value) }
                Button { showEdit = true } label: {
                    Label("Edit details", systemImage: "square.and.pencil").bold()
                }
                .foregroundColor(color)
            } header: {
                SectionTag("Details", systemImage: "person.text.rectangle", color: color)
            }

            // Quyền lợi (đa hình: benefitRows + facilities + accessWindow)
            Section {
                ForEach(m.benefitRows) { InfoRow(label: $0.label, value: $0.value) }
                Text("Included areas").font(.system(size: 12)).foregroundColor(.gray)
                FlowLayout(spacing: 6) {
                    ForEach(m.facilities) { FacilityChip(facility: $0, color: color) }
                }
            } header: {
                SectionTag("Plan benefits", systemImage: "gift.fill", color: color)
            }

            // Phí ước tính (đa hình: chargeLines)
            Section {
                ForEach(b.lines) { InfoRow(label: $0.label, value: $0.amount.vnd) }
                if let p = b.promotion {
                    InfoRow(label: "Promotion \(p.code) (−\(Int(p.percentOff))%)", value: "−" + b.discount.vnd)
                }
                InfoRow(label: "Total", value: b.total.vnd)
                InfoRow(label: "Paid", value: b.paid.vnd)
                HStack {
                    Text("Outstanding").bold()
                    Spacer()
                    Text(b.outstanding.vnd)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(b.outstanding == 0 ? Theme.success : Theme.billing)
                }
            } header: {
                SectionTag("Estimated charges", systemImage: "banknote.fill", color: Theme.billing)
            }

            // Thao tác riêng theo loại gói
            if let p = m as? PremiumMembership {
                PremiumSection(membership: p) { message = $0 }
            } else if let t = m as? PersonalTrainingMembership {
                TrainingSection(membership: t) { message = $0 }
            }
            if m.supportsTemporaryUpgrade {
                UpgradeSection(membership: m) { message = $0 }
            }

            CheckInSection(membership: m) { message = $0 }
            BillingSection(membership: m) { message = $0 }
            StatusSection(membership: m) { message = $0 }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Check-in
struct CheckInSection: View {
    @EnvironmentObject var manager: MembershipManager
    let membership: Membership
    let onMessage: (String) -> Void
    @State private var facility: Facility = .gymFloor
    @State private var time = Date()

    var body: some View {
        Section {
            Picker("Area", selection: $facility) {
                ForEach(Facility.allCases) { f in Text(f.rawValue).tag(f) }
            }
            DatePicker("Check-in time", selection: $time, displayedComponents: .hourAndMinute)
                .font(.system(size: 14))
            Button { checkIn() } label: {
                Label("Check in", systemImage: "qrcode.viewfinder").bold()
            }
            .foregroundColor(Theme.success)
            ForEach(membership.checkIns.suffix(3).reversed()) { r in
                InfoRow(label: r.facility.rawValue, value: r.date.short + " " + r.date.timeText)
            }
        } header: {
            SectionTag("Facility check-in", systemImage: "door.left.hand.open", color: Theme.success)
        }
    }

    private func checkIn() {
        onMessage(manager.attempt {
            let r = try membership.checkIn(at: time, facility: facility, by: manager.currentRole)
            return "Checked in to \(r.facility.rawValue) at \(r.date.timeText)."
        })
    }
}

// MARK: - Billing (thanh toán, đổi phí, khuyến mãi, kỳ mới)
struct BillingSection: View {
    @EnvironmentObject var manager: MembershipManager
    let membership: Membership
    let onMessage: (String) -> Void
    @State private var paymentText = ""
    @State private var feeText = ""

    var body: some View {
        Section {
            TextField("Payment amount", text: $paymentText).keyboardType(.decimalPad)
            Button { pay() } label: {
                Label("Record payment", systemImage: "creditcard.fill").bold()
            }
            .foregroundColor(Theme.billing)
        } header: {
            SectionTag("Payment", systemImage: "creditcard", color: Theme.billing)
        }

        Section {
            TextField(membership.feeLabel, text: $feeText).keyboardType(.decimalPad)
            Button { changeFee() } label: {
                Label("Update \(membership.feeLabel.lowercased())", systemImage: "square.and.arrow.down.fill").bold()
            }
            .foregroundColor(Theme.danger)
        } header: {
            SectionTag("Change fee (Manager only)", systemImage: "lock.shield.fill", color: Theme.danger)
        }
        .onAppear { feeText = String(Int(membership.unitFee)) }

        Section {
            Menu {
                ForEach(manager.promotions) { p in
                    Button("\(p.code) – \(p.title) (\(Int(p.percentOff))%)") { apply(p) }
                }
                Button("Remove promotion", role: .destructive) { removePromo() }
            } label: {
                Label("Apply promotion", systemImage: "tag.fill").bold()
            }
            .foregroundColor(Theme.premium)
            Button { newPeriod() } label: {
                Label("Start new billing period", systemImage: "arrow.clockwise.circle.fill").bold()
            }
            .foregroundColor(Theme.billing)
        } header: {
            SectionTag("Promotions & billing period", systemImage: "tag", color: Theme.premium)
        }
    }

    private func pay() {
        onMessage(manager.attempt {
            let a = try parseAmount(paymentText, field: "Payment")
            try membership.recordPayment(a, by: manager.currentRole)
            paymentText = ""
            return "Payment of \(a.vnd) recorded."
        })
    }

    private func changeFee() {
        onMessage(manager.attempt {
            let f = try parseAmount(feeText, field: membership.feeLabel)
            try membership.updateFee(to: f, by: manager.currentRole)
            return "\(membership.feeLabel) updated to \(f.vnd)."
        })
    }

    private func apply(_ p: Promotion) {
        onMessage(manager.attempt {
            try membership.applyPromotion(p, by: manager.currentRole)
            return "Promotion \(p.code) applied."
        })
    }

    private func removePromo() {
        onMessage(manager.attempt {
            try membership.removePromotion(by: manager.currentRole)
            return "Promotion removed."
        })
    }

    private func newPeriod() {
        onMessage(manager.attempt {
            try membership.startNewBillingPeriod(by: manager.currentRole)
            return "New billing period started. Monthly usage was reset."
        })
    }
}

// MARK: - Status & change requests
struct StatusSection: View {
    @EnvironmentObject var manager: MembershipManager
    let membership: Membership
    let onMessage: (String) -> Void

    var body: some View {
        Section {
            ForEach(MembershipStatus.allCases) { s in
                Button { setStatus(s) } label: {
                    Label("Set \(s.rawValue)", systemImage: "circle.fill").font(.system(size: 14))
                }
                .foregroundColor(Theme.color(for: s))
            }
        } header: {
            SectionTag("Membership status", systemImage: "shield.lefthalf.filled", color: Theme.warning)
        }

        Section {
            if let r = membership.pendingRequest {
                InfoRow(label: "Pending request", value: r.kind.rawValue)
                Button { resolve(true) } label: { Label("Approve request", systemImage: "checkmark.circle.fill") }
                    .foregroundColor(Theme.success)
                Button { resolve(false) } label: { Label("Reject request", systemImage: "xmark.circle.fill") }
                    .foregroundColor(Theme.danger)
            } else {
                Text("No pending request.").foregroundColor(.gray)
            }
            ForEach(RequestKind.allCases) { k in
                Button { submit(k) } label: {
                    Label("Request: \(k.rawValue)", systemImage: "paperplane.fill").font(.system(size: 14))
                }
                .foregroundColor(Theme.members)
            }
        } header: {
            SectionTag("Change requests", systemImage: "tray.full.fill", color: Theme.members)
        }
    }

    private func setStatus(_ s: MembershipStatus) {
        onMessage(manager.attempt {
            try membership.setStatus(s, by: manager.currentRole)
            return "Status changed to \(s.rawValue)."
        })
    }

    private func submit(_ k: RequestKind) {
        onMessage(manager.attempt {
            try membership.submitRequest(k, by: manager.currentRole)
            return "Request submitted: \(k.rawValue)."
        })
    }

    private func resolve(_ approve: Bool) {
        onMessage(manager.attempt {
            try membership.resolveRequest(approve: approve, by: manager.currentRole)
            return approve ? "Request approved." : "Request rejected."
        })
    }
}

// MARK: - Premium: group classes (giới hạn theo tháng)
struct PremiumSection: View {
    @EnvironmentObject var manager: MembershipManager
    let membership: PremiumMembership
    let onMessage: (String) -> Void
    @State private var className = ""

    var body: some View {
        Section {
            InfoRow(label: "Classes this month", value: "\(membership.classesUsed)/\(membership.monthlyClassLimit)")
            TextField("Class name (e.g. Yoga)", text: $className)
            Button { book() } label: {
                Label("Book group class", systemImage: "calendar.badge.plus").bold()
            }
            .foregroundColor(Theme.premium)
            ForEach(Array(membership.bookedClasses.suffix(3).enumerated()), id: \.offset) { _, c in
                Text("• " + c).font(.system(size: 13)).foregroundColor(.gray)
            }
        } header: {
            SectionTag("Group classes", systemImage: "person.3.fill", color: Theme.premium)
        }
    }

    private func book() {
        onMessage(manager.attempt {
            try membership.bookGroupClass(named: className, by: manager.currentRole)
            let used = membership.classesUsed
            className = ""
            return "Class booked (\(used)/\(membership.monthlyClassLimit))."
        })
    }
}

// MARK: - Personal training: buổi tập
struct TrainingSection: View {
    @EnvironmentObject var manager: MembershipManager
    let membership: PersonalTrainingMembership
    let onMessage: (String) -> Void
    @State private var addText = "2"

    var body: some View {
        Section {
            InfoRow(label: "Remaining sessions", value: "\(membership.sessionsRemaining) of \(membership.sessionsPurchased)")
            Button { attend() } label: {
                Label("Record attended session", systemImage: "checkmark.circle.fill").bold()
            }
            .foregroundColor(Theme.training)
            TextField("Sessions to add (1 – 20)", text: $addText).keyboardType(.numbersAndPunctuation)
            Button { add() } label: {
                Label("Add sessions", systemImage: "plus.circle.fill").bold()
            }
            .foregroundColor(Theme.training)
        } header: {
            SectionTag("Coaching sessions", systemImage: "figure.strengthtraining.traditional", color: Theme.training)
        }
    }

    private func attend() {
        onMessage(manager.attempt {
            try membership.attendSession(by: manager.currentRole)
            return "Session recorded. Remaining: \(membership.sessionsRemaining)."
        })
    }

    private func add() {
        onMessage(manager.attempt {
            let n = try parseInt(addText, field: "Sessions")
            try membership.addSessions(n, by: manager.currentRole)
            return "Added \(n) session(s). Charges updated."
        })
    }
}

// MARK: - Temporary upgrade
struct UpgradeSection: View {
    @EnvironmentObject var manager: MembershipManager
    let membership: Membership
    let onMessage: (String) -> Void
    @State private var daysText = "7"

    var body: some View {
        Section {
            if let d = membership.temporaryUpgradeUntil, membership.hasTemporaryUpgrade {
                InfoRow(label: "Upgrade active until", value: d.short)
            }
            TextField("Days (1 – 30)", text: $daysText).keyboardType(.numbersAndPunctuation)
            Button { grant() } label: {
                Label("Grant temporary upgrade", systemImage: "arrow.up.circle.fill").bold()
            }
            .foregroundColor(Theme.premium)
        } header: {
            SectionTag("Temporary upgrade", systemImage: "sparkles", color: Theme.premium)
        }
    }

    private func grant() {
        onMessage(manager.attempt {
            let d = try parseInt(daysText, field: "Days")
            try membership.grantTemporaryUpgrade(days: d, by: manager.currentRole)
            return "Premium access granted for \(d) day(s)."
        })
    }
}

// MARK: - Edit details (Staff)
struct EditMemberView: View {
    @EnvironmentObject var manager: MembershipManager
    @Environment(\.dismiss) var dismiss

    let membership: Membership
    let onDone: (String) -> Void
    @State private var name: String
    @State private var phone: String
    @State private var message: String?

    init(membership: Membership, onDone: @escaping (String) -> Void) {
        self.membership = membership
        self.onDone = onDone
        _name = State(initialValue: membership.memberName)
        _phone = State(initialValue: membership.phone)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Membership ID", value: membership.id)             // không thể sửa
                    LabeledContent("Activated", value: membership.activationDate.short) // không thể sửa
                    TextField("Member name", text: $name)
                    TextField("Phone", text: $phone).keyboardType(.phonePad)
                } header: {
                    SectionTag("Member Info", systemImage: "person.text.rectangle", color: Theme.members)
                }
            }
            .navigationTitle("Edit Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.bold() }
            }
            .messageAlert("Notice", message: $message)
        }
    }

    private func save() {
        let result = manager.attempt {
            try membership.updateDetails(name: name, phone: phone, by: manager.currentRole)
            return "Membership details updated."
        }
        if result.hasPrefix("Rejected: ") {
            message = result
        } else {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { onDone(result) }
        }
    }
}

#Preview {
    NavigationStack { MemberDetailView(membershipID: "M003") }
        .environmentObject(MembershipManager.preview())
}
