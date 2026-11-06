import Foundation

enum ContractModel: String, CaseIterable {
    case fixedMonthly = "Fixed payment"
    case milestoneBased = "Milestone-based"
}

struct Milestone: Identifiable {
    let id = UUID()
    fileprivate(set) var title: String
    fileprivate(set) var amount: Double
    fileprivate(set) var approvedMonth: PayMonth?     // tháng được thanh toán
    var isApproved: Bool { approvedMonth != nil }

    init(title: String, amount: Double) {
        self.title = title
        self.amount = amount
        self.approvedMonth = nil
    }
}

final class ContractEmployee: Employee {
    let contractModel: ContractModel
    private(set) var fixedMonthlyAmount: Double
    private(set) var milestones: [Milestone] = []

    init(id: String, name: String, department: String, position: String, hireDate: Date,
         performanceRating: Double = 3.0, contractModel: ContractModel, fixedMonthlyAmount: Double = 0) {
        self.contractModel = contractModel
        self.fixedMonthlyAmount = fixedMonthlyAmount
        super.init(id: id, name: name, department: department, position: position,
                   hireDate: hireDate, performanceRating: performanceRating)
    }

    override var employmentType: EmploymentType { .contract }
    override var typeName: String { "Contract (\(contractModel.rawValue))" }
    override var icon: String { "doc.text.fill" }
    override var bonusPolicyText: String {
        contractModel == .milestoneBased ? "Rating ≥ 4.5: +5% of approved milestones" : "Not eligible (fixed payment)"
    }

    override func performanceBonusRate(for rating: Double) -> Double {
        (contractModel == .milestoneBased && rating >= 4.5) ? 0.05 : 0
    }

    func approvedMilestones(in month: PayMonth) -> [Milestone] {
        milestones.filter { $0.approvedMonth == month }
    }

    override func compensationLines(for month: PayMonth) -> [PayLine] {
        switch contractModel {
        case .fixedMonthly:
            return [PayLine(label: "Fixed contract payment", amount: fixedMonthlyAmount)]
        case .milestoneBased:
            let done = approvedMilestones(in: month)
            var lines = done.map { PayLine(label: "Milestone: \($0.title)", amount: $0.amount) }
            let sum = done.reduce(0) { $0 + $1.amount }
            if let b = bonusLine(base: sum) { lines.append(b) }
            return lines
        }
    }

    override var compensationRows: [InfoItem] {
        var rows = [InfoItem(label: "Contract model", value: contractModel.rawValue)]
        if contractModel == .fixedMonthly {
            rows.append(InfoItem(label: "Fixed payment / month", value: fixedMonthlyAmount.vnd))
        } else {
            let paid = milestones.filter { $0.isApproved }.count
            rows.append(InfoItem(label: "Milestones", value: "\(paid) approved / \(milestones.count) total"))
        }
        rows.append(InfoItem(label: "Bonus policy", value: bonusPolicyText))
        return rows
    }

    // MARK: Operations
    func setFixedAmount(_ amount: Double, by role: UserRole) throws {
        try authorize(role, .editCompensation, action: "Change contract payment")
        guard contractModel == .fixedMonthly else { throw PayrollError.notFixedContract }
        guard amount.isFinite, amount > 0 else { throw PayrollError.invalidAmount("Fixed payment") }
        fixedMonthlyAmount = amount
    }

    func addMilestone(title: String, amount: Double, by role: UserRole) throws {
        try authorize(role, .editCompensation, action: "Add milestone")
        guard contractModel == .milestoneBased else { throw PayrollError.notMilestoneContract }
        let t = title.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { throw PayrollError.emptyField("Milestone title") }
        guard amount.isFinite, amount > 0 else { throw PayrollError.invalidAmount("Milestone amount") }
        milestones.append(Milestone(title: t, amount: amount))
    }

    /// Milestone đã duyệt thì bị khoá — chỉ sửa được qua correction procedure.
    func updateMilestoneAmount(id: UUID, newAmount: Double, by role: UserRole) throws {
        try authorize(role, .editCompensation, action: "Change milestone amount")
        guard let i = milestones.firstIndex(where: { $0.id == id }) else { throw PayrollError.milestoneNotFound }
        guard !milestones[i].isApproved else { throw PayrollError.milestoneLocked(milestones[i].title) }
        guard newAmount.isFinite, newAmount > 0 else { throw PayrollError.invalidAmount("Milestone amount") }
        milestones[i].amount = newAmount
    }

    func approveMilestone(id: UUID, in month: PayMonth, by role: UserRole) throws {
        try authorize(role, .approvePayment, action: "Approve milestone")
        guard contractModel == .milestoneBased else { throw PayrollError.notMilestoneContract }
        guard let i = milestones.firstIndex(where: { $0.id == id }) else { throw PayrollError.milestoneNotFound }
        guard !milestones[i].isApproved else { throw PayrollError.milestoneAlreadyApproved(milestones[i].title) }
        try ensureMonthOpen(month)
        milestones[i].approvedMonth = month
    }
}
