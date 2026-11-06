import SwiftUI

struct AppointmentDetailView: View {
    @EnvironmentObject var manager: ClinicManager
    let appointmentID: String
    @State private var message: String?
    @State private var showEdit = false

    var body: some View {
        Group {
            if let a = manager.appointment(withID: appointmentID) {
                content(a)
            } else {
                EmptyHint(systemImage: "questionmark.folder", text: "Appointment not found.")
            }
        }
        .navigationTitle("Appointment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { RolePicker() } }
        .sheet(isPresented: $showEdit) {
            if let a = manager.appointment(withID: appointmentID) {
                EditNotesView(appointment: a) { message = $0 }.environmentObject(manager)
            }
        }
        .messageAlert("Result", message: $message)
    }

    private func content(_ a: Appointment) -> some View {
        let color = Theme.color(for: a.type)
        let b = a.breakdown
        return List {
            // Header
            Section {
                HStack(spacing: 12) {
                    IconBadge(systemName: a.icon, color: color)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(a.pet.name) · \(a.owner.name)").font(.headline)
                        HStack(spacing: 6) {
                            IDChip(text: a.id, color: color)
                            StatusPill(text: a.status.rawValue, color: Theme.color(for: a.status))
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

            // Thông tin lượt khám (đa hình: detailRows / typeSpecificRows)
            Section {
                ForEach(a.detailRows) { InfoRow(label: $0.label, value: $0.value) }
                InfoRow(label: "Pet", value: "\(a.pet.name) (\(a.pet.species.rawValue), \(a.pet.ageYears)y)")
                InfoRow(label: "Owner phone", value: a.owner.phone)
                Button { showEdit = true } label: {
                    Label("Edit notes", systemImage: "square.and.pencil").bold()
                }
                .foregroundColor(color)
            } header: {
                SectionTag("Visit details", systemImage: "doc.text.fill", color: color)
            }

            // Phí ước tính (đa hình: chargeLines)
            Section {
                ForEach(b.lines) { InfoRow(label: $0.label, value: $0.amount.vnd) }
                if let p = b.promotion {
                    InfoRow(label: "Promotion \(p.code) (−\(Int(p.percentOff))%)", value: "−" + b.discount.vnd)
                }
                HStack {
                    Text("Estimated total").bold()
                    Spacer()
                    Text(a.estimatedCharges.vnd)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.charges)
                }
                HStack {
                    Text("Charges").foregroundColor(.gray)
                    Spacer()
                    StatusPill(text: a.chargesLocked ? "Locked (confirmed)" : "Open",
                               color: a.chargesLocked ? Theme.charges : Theme.success)
                }
            } header: {
                SectionTag("Estimated charges", systemImage: "banknote.fill", color: Theme.charges)
            }

            // Hành động khả dụng (khác nhau theo loại & trạng thái)
            Section {
                if a.availableActions.isEmpty {
                    Text("No actions available.").foregroundColor(.gray)
                }
                ForEach(a.availableActions, id: \.self) { Text("• " + $0).font(.system(size: 14)) }
            } header: {
                SectionTag("Available actions", systemImage: "list.bullet.clipboard", color: color)
            }

            // Phần riêng theo loại lịch hẹn
            if let v = a as? VaccinationAppointment {
                VaccinationSection(appointment: v) { message = $0 }
            } else if let e = a as? EmergencyAppointment {
                EmergencySection(appointment: e)
            }

            WorkflowSection(appointment: a) { message = $0 }
            ScheduleSection(appointment: a) { message = $0 }
            ServicesSection(appointment: a) { message = $0 }
            PricingSection(appointment: a) { message = $0 }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Workflow: confirm → check-in → complete / cancel
struct WorkflowSection: View {
    @EnvironmentObject var manager: ClinicManager
    let appointment: Appointment
    let onMessage: (String) -> Void

    var body: some View {
        Section {
            Button { run("Appointment confirmed. Charges are now locked.") { try appointment.confirm(by: manager.currentRole) } } label: {
                Label("Confirm booking", systemImage: "checkmark.seal.fill").bold()
            }
            .foregroundColor(Theme.routine)
            Button { run("Pet checked in.") { try appointment.checkIn(by: manager.currentRole) } } label: {
                Label("Check in", systemImage: "door.left.hand.open").bold()
            }
            .foregroundColor(Theme.warning)
            Button { run("Visit completed.") { try appointment.complete(by: manager.currentRole) } } label: {
                Label("Complete visit", systemImage: "checkmark.circle.fill").bold()
            }
            .foregroundColor(Theme.success)
            Button { run("Appointment cancelled.") { try appointment.cancel(by: manager.currentRole) } } label: {
                Label("Cancel appointment", systemImage: "xmark.circle.fill").bold()
            }
            .foregroundColor(Theme.danger)
        } header: {
            SectionTag("Visit workflow", systemImage: "arrow.triangle.branch", color: Theme.appointments)
        }
    }

    private func run(_ success: String, _ action: () throws -> Void) {
        onMessage(manager.attempt {
            try action()
            return "✅ " + success
        })
    }
}

// MARK: - Schedule: đổi lịch, yêu cầu từ chủ nuôi, amendment
struct ScheduleSection: View {
    @EnvironmentObject var manager: ClinicManager
    let appointment: Appointment
    let onMessage: (String) -> Void
    @State private var newDate = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
    @State private var reason = ""

    var body: some View {
        Section {
            DatePicker("New date & time", selection: $newDate).font(.system(size: 14))
            Button { reschedule() } label: {
                Label("Reschedule", systemImage: "calendar.badge.clock").bold()
            }
            .foregroundColor(Theme.routine)
        } header: {
            SectionTag("Reschedule", systemImage: "calendar", color: Theme.routine)
        }

        Section {
            if let r = appointment.pendingRequest {
                InfoRow(label: "Pending request", value: r.kind.title)
                Button { resolve(true) } label: { Label("Approve request", systemImage: "checkmark.circle.fill") }
                    .foregroundColor(Theme.success)
                Button { resolve(false) } label: { Label("Reject request", systemImage: "xmark.circle.fill") }
                    .foregroundColor(Theme.danger)
            } else {
                Text("No pending request.").foregroundColor(.gray)
            }
            Button { request(.cancel) } label: {
                Label("Request: cancel appointment", systemImage: "paperplane.fill").font(.system(size: 14))
            }
            .foregroundColor(Theme.appointments)
            Button { request(.reschedule(newDate)) } label: {
                Label("Request: reschedule to chosen date", systemImage: "paperplane.fill").font(.system(size: 14))
            }
            .foregroundColor(Theme.appointments)
        } header: {
            SectionTag("Owner requests", systemImage: "tray.full.fill", color: Theme.appointments)
        }

        Section {
            ForEach(appointment.amendments) { am in
                InfoRow(label: am.date.short, value: am.reason)
            }
            TextField("Reason for amendment", text: $reason)
            Button { reopen() } label: {
                Label("Reopen completed visit (Manager)", systemImage: "arrow.uturn.backward.circle.fill").bold()
            }
            .foregroundColor(Theme.danger)
        } header: {
            SectionTag("Amendment procedure", systemImage: "exclamationmark.arrow.triangle.2.circlepath", color: Theme.danger)
        }
    }

    private func reschedule() {
        onMessage(manager.attempt {
            try appointment.reschedule(to: newDate, by: manager.currentRole)
            return "✅ Rescheduled to \(newDate.dateTimeText)."
        })
    }

    private func request(_ kind: ChangeRequestKind) {
        onMessage(manager.attempt {
            try appointment.submitRequest(kind, by: manager.currentRole)
            return "✅ Request submitted: \(kind.title)."
        })
    }

    private func resolve(_ approve: Bool) {
        onMessage(manager.attempt {
            try appointment.resolveRequest(approve: approve, by: manager.currentRole)
            return approve ? "✅ Request approved." : "✅ Request rejected."
        })
    }

    private func reopen() {
        onMessage(manager.attempt {
            try appointment.reopenCompletedVisit(reason: reason, by: manager.currentRole)
            reason = ""
            return "✅ Visit reopened through the amendment procedure."
        })
    }
}

// MARK: - Dịch vụ thêm
struct ServicesSection: View {
    @EnvironmentObject var manager: ClinicManager
    let appointment: Appointment
    let onMessage: (String) -> Void

    var body: some View {
        Section {
            if appointment.services.isEmpty {
                Text("No extra services.").foregroundColor(.gray)
            }
            ForEach(appointment.services) { s in InfoRow(label: s.name, value: s.price.vnd) }
            Menu {
                ForEach(ServiceItem.catalog) { s in
                    Button("\(s.name) – \(s.price.vnd)") { add(s) }
                }
            } label: {
                Label("Add service", systemImage: "plus.circle.fill").bold()
            }
            .foregroundColor(Theme.appointments)
        } header: {
            SectionTag("Additional services", systemImage: "cross.case", color: Theme.appointments)
        }
    }

    private func add(_ s: ServiceItem) {
        onMessage(manager.attempt {
            try appointment.addService(s, by: manager.currentRole)
            return "✅ Added \(s.name)."
        })
    }
}

// MARK: - Giá & khuyến mãi (khóa sau khi xác nhận)
struct PricingSection: View {
    @EnvironmentObject var manager: ClinicManager
    let appointment: Appointment
    let onMessage: (String) -> Void
    @State private var feeText = ""

    var body: some View {
        Section {
            TextField(appointment.feeLabel, text: $feeText).keyboardType(.decimalPad)
            Button { changeFee() } label: {
                Label("Update \(appointment.feeLabel.lowercased()) (Manager)", systemImage: "square.and.arrow.down.fill").bold()
            }
            .foregroundColor(Theme.danger)
            Menu {
                ForEach(manager.promotions) { p in
                    Button("\(p.code) – \(p.title) (\(Int(p.percentOff))%)") { apply(p) }
                }
                Button("Remove promotion", role: .destructive) { remove() }
            } label: {
                Label("Apply discount / bundle", systemImage: "tag.fill").bold()
            }
            .foregroundColor(Theme.vaccination)
        } header: {
            SectionTag("Pricing", systemImage: "lock.shield.fill", color: Theme.danger)
        }
        .onAppear { feeText = String(Int(appointment.baseFee)) }
    }

    private func changeFee() {
        onMessage(manager.attempt {
            let f = try parseAmount(feeText, field: appointment.feeLabel)
            try appointment.updateBaseFee(to: f, by: manager.currentRole)
            return "✅ \(appointment.feeLabel) updated to \(f.vnd)."
        })
    }

    private func apply(_ p: Promotion) {
        onMessage(manager.attempt {
            try appointment.applyPromotion(p, by: manager.currentRole)
            return "✅ Promotion \(p.code) applied."
        })
    }

    private func remove() {
        onMessage(manager.attempt {
            try appointment.removePromotion(by: manager.currentRole)
            return "✅ Promotion removed."
        })
    }
}

// MARK: - Vaccination: chọn vắc-xin + lịch sử tiêm
struct VaccinationSection: View {
    @EnvironmentObject var manager: ClinicManager
    let appointment: VaccinationAppointment
    let onMessage: (String) -> Void

    var body: some View {
        Section {
            InfoRow(label: "Selected vaccine", value: appointment.vaccine?.name ?? "Not selected")
            Menu {
                ForEach(Vaccine.catalog) { v in
                    Button("\(v.name) – \(v.price.vnd)") { select(v) }
                }
            } label: {
                Label("Select vaccine", systemImage: "syringe.fill").bold()
            }
            .foregroundColor(Theme.vaccination)
            Text("Vaccination history of \(appointment.pet.name)").font(.system(size: 12)).foregroundColor(.gray)
            if appointment.pet.vaccinationHistory.isEmpty {
                Text("No previous vaccinations.").foregroundColor(.gray)
            }
            ForEach(appointment.pet.vaccinationHistory) { r in
                InfoRow(label: r.vaccineName, value: r.date.short)
            }
        } header: {
            SectionTag("Vaccination", systemImage: "syringe", color: Theme.vaccination)
        }
    }

    private func select(_ v: Vaccine) {
        onMessage(manager.attempt {
            try appointment.selectVaccine(v, by: manager.currentRole)
            return "✅ Vaccine set to \(v.name)."
        })
    }
}

// MARK: - Emergency
struct EmergencySection: View {
    let appointment: EmergencyAppointment

    var body: some View {
        Section {
            Label("Priority case — immediate attention, no rescheduling.", systemImage: "exclamationmark.triangle.fill")
                .font(.system(size: 13))
                .foregroundColor(Theme.emergency)
            InfoRow(label: "Urgency surcharge", value: appointment.urgency.surcharge.vnd)
            InfoRow(label: "After-hours surcharge", value: appointment.isAfterHours ? "Applied" : "Not applied")
        } header: {
            SectionTag("Emergency triage", systemImage: "cross.case.fill", color: Theme.emergency)
        }
    }
}

// MARK: - Edit notes
struct EditNotesView: View {
    @EnvironmentObject var manager: ClinicManager
    @Environment(\.dismiss) var dismiss

    let appointment: Appointment
    let onDone: (String) -> Void
    @State private var notes: String
    @State private var message: String?

    init(appointment: Appointment, onDone: @escaping (String) -> Void) {
        self.appointment = appointment
        self.onDone = onDone
        _notes = State(initialValue: appointment.notes)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Appointment ID", value: appointment.id)      // không thể sửa
                    LabeledContent("Pet", value: appointment.pet.name)           // không thể sửa
                    TextField("Notes", text: $notes, axis: .vertical).lineLimit(2...5)
                } header: {
                    SectionTag("Appointment Info", systemImage: "doc.text", color: Theme.appointments)
                }
            }
            .navigationTitle("Edit Notes")
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
            try appointment.updateNotes(notes, by: manager.currentRole)
            return "✅ Notes updated."
        }
        if result.hasPrefix("⛔️") {
            message = result
        } else {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { onDone(result) }
        }
    }
}

#Preview {
    NavigationStack { AppointmentDetailView(appointmentID: "A003") }
        .environmentObject(ClinicManager.preview())
}
