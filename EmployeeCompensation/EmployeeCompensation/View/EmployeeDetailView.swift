import SwiftUI

struct EmployeeDetailView: View {
    @EnvironmentObject var manager: PayrollManager
    let employeeID: String
    @State private var message: String?
    @State private var showEdit = false

    var body: some View {
        Group {
            if let e = manager.employee(withID: employeeID) {
                content(e)
            } else {
                EmptyHint(systemImage: "questionmark.folder", text: "Employee not found.")
            }
        }
        .navigationTitle("EMPLOYEE")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { RolePicker() } }
        .sheet(isPresented: $showEdit) {
            if let e = manager.employee(withID: employeeID) {
                EditEmployeeView(employee: e) { message = $0 }.environmentObject(manager)
            }
        }
        .messageAlert("Result", message: $message)
    }

    private func content(_ e: Employee) -> some View {
        let color = Theme.color(for: e.employmentType)
        return List {
            // Header
            Section {
                HStack(spacing: 12) {
                    IconBadge(systemName: e.icon, color: color)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(e.name).font(.headline)
                        HStack(spacing: 6) {
                            IDChip(text: e.id, color: color)
                            StatusPill(text: e.typeName, color: color)
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

            // Thông tin chung (HR có thể cập nhật)
            Section {
                ForEach(e.detailRows) { InfoRow(label: $0.label, value: $0.value) }
                Button { showEdit = true } label: {
                    Label("Edit information", systemImage: "square.and.pencil").bold()
                }
                .foregroundColor(color)
            } header: {
                SectionTag("Information", systemImage: "person.text.rectangle", color: color)
            }

            // Thông tin lương riêng của từng loại (đa hình: compensationRows)
            Section {
                ForEach(e.compensationRows) { InfoRow(label: $0.label, value: $0.value) }
            } header: {
                SectionTag("Compensation details", systemImage: "banknote.fill", color: color)
            }

            // Thao tác riêng theo loại nhân viên
            if let ft = e as? FullTimeEmployee {
                FullTimeSection(employee: ft) { message = $0 }
            } else if let pt = e as? PartTimeEmployee {
                PartTimeSection(employee: pt) { message = $0 }
            } else if let ct = e as? ContractEmployee {
                ContractSection(employee: ct) { message = $0 }
            }

            PaymentSection(employee: e) { message = $0 }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Full-time
struct FullTimeSection: View {
    @EnvironmentObject var manager: PayrollManager
    let employee: FullTimeEmployee
    let onMessage: (String) -> Void
    @State private var salaryText = ""
    @State private var allowanceText = ""

    var body: some View {
        Section {
            TextField("Monthly salary", text: $salaryText).keyboardType(.decimalPad)
            TextField("Allowance", text: $allowanceText).keyboardType(.decimalPad)
            Button { save() } label: {
                Label("Update compensation", systemImage: "square.and.arrow.down.fill").bold()
            }
            .foregroundColor(Theme.fullTime)
        } header: {
            SectionTag("Update salary / allowance", systemImage: "pencil.and.list.clipboard", color: Theme.fullTime)
        }
        .onAppear {
            salaryText = String(Int(employee.monthlySalary))
            allowanceText = String(Int(employee.allowance))
        }
    }

    private func save() {
        onMessage(manager.attempt {
            let s = try parseAmount(salaryText, field: "Monthly salary")
            let a = try parseAmount(allowanceText, field: "Allowance")
            try employee.updateCompensation(salary: s, allowance: a, by: manager.currentRole)
            return "Compensation updated."
        })
    }
}

// MARK: - Part-time
struct PartTimeSection: View {
    @EnvironmentObject var manager: PayrollManager
    let employee: PartTimeEmployee
    let onMessage: (String) -> Void
    @State private var hoursText = ""
    @State private var date = Date()
    @State private var rateText = ""

    var body: some View {
        let month = manager.selectedMonth
        Section {
            TextField("Hours (e.g. 6.5 — try -3)", text: $hoursText).keyboardType(.numbersAndPunctuation)
            DatePicker("Work date", selection: $date, displayedComponents: .date).font(.system(size: 14))
            Button { record() } label: {
                Label("Record hours", systemImage: "clock.badge.checkmark.fill").bold()
            }
            .foregroundColor(Theme.partTime)
        } header: {
            SectionTag("Record working hours", systemImage: "clock.fill", color: Theme.partTime)
        }

        Section {
            let total = employee.hours(in: month)
            InfoRow(label: "Total hours", value: String(format: "%.1f / %.0f h", total, PartTimeEmployee.maxMonthlyHours))
            if employee.logs(in: month).isEmpty {
                Text("No hours recorded.").foregroundColor(.gray)
            }
            ForEach(employee.logs(in: month)) { l in
                InfoRow(label: l.date.short, value: String(format: "%.1f h", l.hours))
            }
        } header: {
            SectionTag("Work log – \(month.title)", systemImage: "list.bullet.rectangle", color: Theme.partTime)
        }

        Section {
            TextField("Hourly rate", text: $rateText).keyboardType(.decimalPad)
            Button { saveRate() } label: {
                Label("Update hourly rate", systemImage: "square.and.arrow.down.fill").bold()
            }
            .foregroundColor(Theme.partTime)
        } header: {
            SectionTag("Hourly rate", systemImage: "banknote", color: Theme.partTime)
        }
        .onAppear { rateText = String(Int(employee.hourlyRate)) }
    }

    private func record() {
        onMessage(manager.attempt {
            let h = try parseAmount(hoursText, field: "Hours")
            try employee.recordHours(h, on: date, by: manager.currentRole)
            hoursText = ""
            return "Recorded \(String(format: "%.1f", h)) h on \(date.short)."
        })
    }

    private func saveRate() {
        onMessage(manager.attempt {
            let r = try parseAmount(rateText, field: "Hourly rate")
            try employee.setHourlyRate(r, by: manager.currentRole)
            return "Hourly rate updated."
        })
    }
}

// MARK: - Contract
struct ContractSection: View {
    @EnvironmentObject var manager: PayrollManager
    let employee: ContractEmployee
    let onMessage: (String) -> Void
    @State private var fixedText = ""
    @State private var newTitle = ""
    @State private var newAmount = ""

    var body: some View {
        if employee.contractModel == .fixedMonthly {
            Section {
                TextField("Fixed payment / month", text: $fixedText).keyboardType(.decimalPad)
                Button { saveFixed() } label: {
                    Label("Update fixed payment", systemImage: "square.and.arrow.down.fill").bold()
                }
                .foregroundColor(Theme.contract)
            } header: {
                SectionTag("Fixed payment", systemImage: "banknote", color: Theme.contract)
            }
            .onAppear { fixedText = String(Int(employee.fixedMonthlyAmount)) }
        } else {
            Section {
                ForEach(employee.milestones) { m in
                    MilestoneRow(employee: employee, milestone: m, onMessage: onMessage)
                }
            } header: {
                SectionTag("Milestones", systemImage: "flag.checkered", color: Theme.contract)
            }
            Section {
                TextField("Milestone title", text: $newTitle)
                TextField("Amount", text: $newAmount).keyboardType(.decimalPad)
                Button { addMilestone() } label: {
                    Label("Add milestone", systemImage: "plus.circle.fill").bold()
                }
                .foregroundColor(Theme.contract)
            } header: {
                SectionTag("New milestone", systemImage: "plus", color: Theme.contract)
            }
        }
    }

    private func saveFixed() {
        onMessage(manager.attempt {
            let a = try parseAmount(fixedText, field: "Fixed payment")
            try employee.setFixedAmount(a, by: manager.currentRole)
            return "Fixed payment updated."
        })
    }

    private func addMilestone() {
        onMessage(manager.attempt {
            let a = try parseAmount(newAmount, field: "Milestone amount")
            try employee.addMilestone(title: newTitle, amount: a, by: manager.currentRole)
            newTitle = ""; newAmount = ""
            return "Milestone added."
        })
    }
}

struct MilestoneRow: View {
    @EnvironmentObject var manager: PayrollManager
    let employee: ContractEmployee
    let milestone: Milestone
    let onMessage: (String) -> Void
    @State private var text = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(milestone.title).font(.headline)
                Spacer()
                if let m = milestone.approvedMonth {
                    StatusPill(text: "Paid in \(m.title)", color: Theme.success)
                } else {
                    StatusPill(text: "Pending", color: Theme.warning)
                }
            }
            HStack(spacing: 10) {
                TextField("Amount", text: $text)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                Button("Save") { save() }
                    .buttonStyle(.borderless).foregroundColor(Theme.contract)
                if !milestone.isApproved {
                    Button("Approve") { approve() }
                        .buttonStyle(.borderless).foregroundColor(Theme.success)
                }
            }
        }
        .onAppear { text = String(Int(milestone.amount)) }
    }

    private func save() {
        onMessage(manager.attempt {
            let a = try parseAmount(text, field: "Milestone amount")
            try employee.updateMilestoneAmount(id: milestone.id, newAmount: a, by: manager.currentRole)
            return "Milestone amount updated."
        })
    }

    private func approve() {
        onMessage(manager.attempt {
            try employee.approveMilestone(id: milestone.id, in: manager.selectedMonth, by: manager.currentRole)
            return "Milestone approved and added to \(manager.selectedMonth.title) payroll."
        })
    }
}

// MARK: - Monthly pay, approval & correction
struct PaymentSection: View {
    @EnvironmentObject var manager: PayrollManager
    let employee: Employee
    let onMessage: (String) -> Void
    @State private var adjustmentText = ""
    @State private var reason = ""

    var body: some View {
        let month = manager.selectedMonth
        let approved = employee.isApproved(month)

        Section {
            MonthSwitcher()
            ForEach(employee.displayLines(for: month)) { l in
                InfoRow(label: l.label, value: l.amount.vnd)
            }
            ForEach(employee.corrections(for: month)) { c in
                InfoRow(label: "Correction: \(c.reason)",
                        value: (c.adjustment >= 0 ? "+" : "−") + abs(c.adjustment).vnd)
            }
            HStack {
                Text("Net payable").bold()
                Spacer()
                Text(employee.finalPayable(for: month).vnd)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.payroll)
            }
            HStack {
                Text("Status").foregroundColor(.gray)
                Spacer()
                StatusPill(text: approved ? "Approved (locked)" : "Pending",
                           color: approved ? Theme.success : Theme.warning)
            }
        } header: {
            SectionTag("Monthly pay – \(month.title)", systemImage: "doc.plaintext.fill", color: Theme.payroll)
        }

        Section {
            Button { approve(month) } label: {
                Label("Approve payment", systemImage: "checkmark.seal.fill").bold()
            }
            .foregroundColor(Theme.payroll)
            Button { overwrite(month) } label: {
                Label("Edit approved amount directly", systemImage: "lock.open.trianglebadge.exclamationmark.fill")
            }
            .foregroundColor(Theme.warning)
        } header: {
            SectionTag("Approval", systemImage: "checkmark.shield.fill", color: Theme.payroll)
        }

        Section {
            TextField("Adjustment (e.g. 500000 or -200000)", text: $adjustmentText)
                .keyboardType(.numbersAndPunctuation)
            TextField("Reason", text: $reason)
            Button { correct(month) } label: {
                Label("Submit correction", systemImage: "arrow.triangle.2.circlepath").bold()
            }
            .foregroundColor(Theme.danger)
        } header: {
            SectionTag("Correction procedure", systemImage: "exclamationmark.arrow.triangle.2.circlepath", color: Theme.danger)
        }
    }

    private func approve(_ month: PayMonth) {
        onMessage(manager.attempt {
            let r = try employee.approvePayment(for: month, by: manager.currentRole)
            return "Payment for \(month.title) approved: \(r.amount.vnd)."
        })
    }

    private func overwrite(_ month: PayMonth) {
        onMessage(manager.attempt {
            try employee.overwriteApprovedPayment(for: month,
                                                  newAmount: employee.grossPay(for: month) + 1_000_000,
                                                  by: manager.currentRole)
            return "Updated."
        })
    }

    private func correct(_ month: PayMonth) {
        onMessage(manager.attempt {
            let a = try parseAmount(adjustmentText, field: "Adjustment")
            try employee.submitCorrection(for: month, adjustment: a, reason: reason, by: manager.currentRole)
            adjustmentText = ""; reason = ""
            return "Correction recorded for \(month.title)."
        })
    }
}

// MARK: - Edit info (HR)
struct EditEmployeeView: View {
    @EnvironmentObject var manager: PayrollManager
    @Environment(\.dismiss) var dismiss

    let employee: Employee
    let onDone: (String) -> Void
    @State private var name: String
    @State private var department: String
    @State private var position: String
    @State private var ratingText: String
    @State private var message: String?

    init(employee: Employee, onDone: @escaping (String) -> Void) {
        self.employee = employee
        self.onDone = onDone
        _name = State(initialValue: employee.name)
        _department = State(initialValue: employee.department)
        _position = State(initialValue: employee.position)
        _ratingText = State(initialValue: String(format: "%.1f", employee.performanceRating))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Employee ID", value: employee.id)   // không thể sửa
                    TextField("Full name", text: $name)
                    TextField("Department", text: $department)
                    TextField("Position", text: $position)
                    TextField("Performance rating (0 – 5)", text: $ratingText).keyboardType(.decimalPad)
                } header: {
                    SectionTag("Employee Info", systemImage: "person.text.rectangle", color: Theme.employees)
                }
            }
            .navigationTitle("Edit Employee")
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
            try employee.updateInfo(name: name, department: department, position: position, by: manager.currentRole)
            let r = try parseAmount(ratingText, field: "Performance rating")
            try employee.setPerformanceRating(r, by: manager.currentRole)
            return "Employee information updated."
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
    NavigationStack { EmployeeDetailView(employeeID: "E003") }
        .environmentObject(PayrollManager.preview())
}
