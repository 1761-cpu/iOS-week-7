import Foundation

// MARK: - Base class
class Employee: Identifiable {
    // MARK: Stored properties
    let id: String                           
    let hireDate: Date
    private(set) var name: String
    private(set) var department: String
    private(set) var position: String
    private(set) var performanceRating: Double       // 0...5
    private(set) var paymentRecords: [PaymentRecord] = []   // khoản đã duyệt (bất biến)
    private(set) var correctionLog: [Correction] = []

    init(id: String, name: String, department: String, position: String,
         hireDate: Date, performanceRating: Double = 3.0) {
        self.id = id
        self.name = name
        self.department = department
        self.position = position
        self.hireDate = hireDate
        self.performanceRating = performanceRating
    }

    // MARK: Policy hooks (lớp con override)
    var employmentType: EmploymentType { .fullTime }
    var typeName: String { "Employee" }
    var icon: String { "person.fill" }
    var bonusPolicyText: String { "No bonus" }
    var searchableText: String { "" }
    var compensationRows: [InfoItem] { [] }

    /// Eligibility + công thức thưởng khác nhau theo từng loại hợp đồng
    func performanceBonusRate(for rating: Double) -> Double { 0 }

    /// Các dòng lương trong 1 tháng (đa hình)
    func compensationLines(for month: PayMonth) -> [PayLine] { [] }

    var detailRows: [InfoItem] {
        [InfoItem(label: "Employee ID", value: id),
         InfoItem(label: "Type", value: typeName),
         InfoItem(label: "Department", value: department),
         InfoItem(label: "Position", value: position),
         InfoItem(label: "Hired", value: hireDate.short),
         InfoItem(label: "Performance rating", value: String(format: "%.1f / 5.0", performanceRating))]
    }

    // MARK: Shared computed behaviour
    final func bonusLine(base: Double) -> PayLine? {
        let rate = performanceBonusRate(for: performanceRating)
        guard rate > 0, base > 0 else { return nil }
        return PayLine(label: "Performance bonus (\(Int((rate * 100).rounded()))%)", amount: (base * rate).rounded())
    }

    final func grossPay(for month: PayMonth) -> Double {
        compensationLines(for: month).reduce(0) { $0 + $1.amount }
    }

    final func record(for month: PayMonth) -> PaymentRecord? { paymentRecords.first { $0.month == month } }
    final func isApproved(_ month: PayMonth) -> Bool { record(for: month) != nil }
    final func corrections(for month: PayMonth) -> [Correction] { correctionLog.filter { $0.month == month } }
    final func correctionsTotal(for month: PayMonth) -> Double {
        corrections(for: month).reduce(0) { $0 + $1.adjustment }
    }

    /// Số tiền thực lĩnh: nếu đã duyệt → khoản đã duyệt + điều chỉnh; nếu chưa → tính theo thời gian thực
    final func finalPayable(for month: PayMonth) -> Double {
        if let r = record(for: month) { return r.amount + correctionsTotal(for: month) }
        return grossPay(for: month)
    }

    final func displayLines(for month: PayMonth) -> [PayLine] {
        record(for: month)?.lines ?? compensationLines(for: month)
    }

    // MARK: Authorization & guards (dùng chung cho lớp con)
    final func authorize(_ role: UserRole, _ permission: Permission, action: String) throws {
        guard role.can(permission) else {
            throw PayrollError.unauthorized(action: action, role: role.rawValue)
        }
    }

    final func ensureMonthOpen(_ month: PayMonth) throws {
        guard !isApproved(month) else { throw PayrollError.monthAlreadyApproved(month.title) }
    }

    // MARK: HR operations
    final func updateInfo(name: String, department: String, position: String, by role: UserRole) throws {
        try authorize(role, .editInfo, action: "Update employee information")
        let n = name.trimmingCharacters(in: .whitespaces)
        let d = department.trimmingCharacters(in: .whitespaces)
        let p = position.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty else { throw PayrollError.emptyField("Name") }
        guard !d.isEmpty else { throw PayrollError.emptyField("Department") }
        guard !p.isEmpty else { throw PayrollError.emptyField("Position") }
        self.name = n
        self.department = d
        self.position = p
    }

    final func setPerformanceRating(_ rating: Double, by role: UserRole) throws {
        try authorize(role, .editInfo, action: "Update performance rating")
        guard rating.isFinite, (0.0...5.0).contains(rating) else { throw PayrollError.invalidRating(rating) }
        performanceRating = rating
    }

    // MARK: Payroll operations
    @discardableResult
    final func approvePayment(for month: PayMonth, by role: UserRole) throws -> PaymentRecord {
        try authorize(role, .approvePayment, action: "Approve payment")
        try ensureMonthOpen(month)
        let lines = compensationLines(for: month)
        let total = lines.reduce(0) { $0 + $1.amount }
        guard total > 0 else { throw PayrollError.nothingToPay(name) }
        let rec = PaymentRecord(month: month, lines: lines, amount: total, approvedOn: Date())
        paymentRecords.append(rec)
        return rec
    }

    /// Quy trình điều chỉnh: KHÔNG sửa khoản đã duyệt, chỉ thêm 1 correction có lý do.
    final func submitCorrection(for month: PayMonth, adjustment: Double, reason: String, by role: UserRole) throws {
        try authorize(role, .approvePayment, action: "Submit payment correction")
        guard isApproved(month) else { throw PayrollError.monthNotApproved(month.title) }
        let cleanReason = reason.trimmingCharacters(in: .whitespaces)
        guard !cleanReason.isEmpty else { throw PayrollError.correctionReasonRequired }
        guard adjustment.isFinite, adjustment != 0, finalPayable(for: month) + adjustment >= 0 else {
            throw PayrollError.invalidCorrection
        }
        correctionLog.append(Correction(month: month, adjustment: adjustment, reason: cleanReason, date: Date()))
    }

    /// Cố tình sửa trực tiếp khoản đã duyệt → luôn bị từ chối (dùng để demo Task 4).
    final func overwriteApprovedPayment(for month: PayMonth, newAmount: Double, by role: UserRole) throws {
        try authorize(role, .approvePayment, action: "Modify approved payment")
        if isApproved(month) { throw PayrollError.approvedPaymentLocked(month.title) }
        throw PayrollError.monthNotApproved(month.title)
    }
}
