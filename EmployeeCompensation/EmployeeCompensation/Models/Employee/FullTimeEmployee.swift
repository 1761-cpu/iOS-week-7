import Foundation

final class FullTimeEmployee: Employee {
    private(set) var monthlySalary: Double
    private(set) var allowance: Double

    init(id: String, name: String, department: String, position: String, hireDate: Date,
         performanceRating: Double = 3.0, monthlySalary: Double, allowance: Double = 0) {
        self.monthlySalary = monthlySalary
        self.allowance = allowance
        super.init(id: id, name: name, department: department, position: position,
                   hireDate: hireDate, performanceRating: performanceRating)
    }

    override var employmentType: EmploymentType { .fullTime }
    override var typeName: String { "Full-time" }
    override var icon: String { "briefcase.fill" }
    override var bonusPolicyText: String { "Rating ≥ 4.5: 20% of salary · ≥ 4.0: 10%" }

    override func performanceBonusRate(for rating: Double) -> Double {
        if rating >= 4.5 { return 0.20 }
        if rating >= 4.0 { return 0.10 }
        return 0
    }

    override func compensationLines(for month: PayMonth) -> [PayLine] {
        var lines = [PayLine(label: "Monthly salary", amount: monthlySalary)]
        if allowance > 0 { lines.append(PayLine(label: "Allowance", amount: allowance)) }
        if let b = bonusLine(base: monthlySalary) { lines.append(b) }
        return lines
    }

    override var compensationRows: [InfoItem] {
        [InfoItem(label: "Monthly salary", value: monthlySalary.vnd),
         InfoItem(label: "Allowance", value: allowance.vnd),
         InfoItem(label: "Bonus policy", value: bonusPolicyText)]
    }

    func updateCompensation(salary: Double, allowance: Double, by role: UserRole) throws {
        try authorize(role, .editCompensation, action: "Change salary / allowance")
        guard salary.isFinite, salary > 0 else { throw PayrollError.invalidAmount("Monthly salary") }
        guard allowance.isFinite, allowance >= 0 else { throw PayrollError.invalidAmount("Allowance") }
        self.monthlySalary = salary
        self.allowance = allowance
    }
}
