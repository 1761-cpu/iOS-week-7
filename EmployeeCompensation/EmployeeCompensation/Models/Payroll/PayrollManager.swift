import Foundation
import Combine

final class PayrollManager: ObservableObject {
    // MARK: - Data
    @Published private(set) var employees: [Employee] = []
    @Published var currentRole: UserRole = .hrStaff
    @Published var selectedMonth: PayMonth = .current

    init(sample: Bool = false) {
        if sample { loadSampleData() }
    }

    // MARK: - Lookup & search
    func employee(withID id: String) -> Employee? { employees.first { $0.id == id } }

    func search(_ keyword: String, type: EmploymentType?) -> [Employee] {
        let k = keyword.trimmingCharacters(in: .whitespaces).lowercased()
        return employees.filter { e in
            (type == nil || e.employmentType == type)
            && (k.isEmpty
                || e.id.lowercased().contains(k)
                || e.name.lowercased().contains(k)
                || e.department.lowercased().contains(k)
                || e.position.lowercased().contains(k))
        }
    }

    // MARK: - Add
    func addEmployee(_ employee: Employee) throws {
        let cleanID = employee.id.trimmingCharacters(in: .whitespaces)
        guard !cleanID.isEmpty else { throw PayrollError.emptyField("Employee ID") }
        guard !employee.name.trimmingCharacters(in: .whitespaces).isEmpty else { throw PayrollError.emptyField("Name") }
        guard self.employee(withID: cleanID) == nil else { throw PayrollError.duplicateEmployee(cleanID) }
        employees.append(employee)
    }

    // MARK: - Run an operation and refresh the UI
    func attempt(_ action: () throws -> String) -> String {
        defer { objectWillChange.send() }
        do { return try action() } catch { return "Rejected: " + error.localizedDescription }
    }

    // MARK: - Monthly summaries (đa hình: gọi compensationLines của từng loại)
    func summary(of e: Employee, month: PayMonth) -> PaySummary {
        PaySummary(employeeID: e.id, employeeName: e.name, department: e.department,
                   typeName: e.typeName, type: e.employmentType, month: month,
                   lines: e.displayLines(for: month), corrections: e.corrections(for: month),
                   netPayable: e.finalPayable(for: month), isApproved: e.isApproved(month))
    }

    func summaries(for month: PayMonth) -> [PaySummary] {
        employees.map { summary(of: $0, month: month) }
    }

    func totalPayable(for month: PayMonth) -> Double {
        employees.reduce(0) { $0 + $1.finalPayable(for: month) }
    }

    func approveAll(month: PayMonth) -> (approved: Int, errors: [String]) {
        defer { objectWillChange.send() }
        guard currentRole.can(.approvePayment) else {
            return (0, [PayrollError.unauthorized(action: "Approve payment", role: currentRole.rawValue).localizedDescription])
        }
        var ok = 0
        var errs: [String] = []
        for e in employees where !e.isApproved(month) {
            do { try e.approvePayment(for: month, by: currentRole); ok += 1 }
            catch { errs.append("\(e.name): \(error.localizedDescription)") }
        }
        return (ok, errs)
    }

    // MARK: - Sample data
    private func loadSampleData() {
        let cur = PayMonth.current
        let prev = cur.previous
        let admin = UserRole.payrollAdmin
        func yearsAgo(_ n: Int) -> Date { Calendar.current.date(byAdding: .year, value: -n, to: Date()) ?? Date() }

        let list: [Employee] = [
            FullTimeEmployee(id: "E001", name: "Nguyễn Ánh", department: "Engineering", position: "Software Engineer",
                             hireDate: yearsAgo(3), performanceRating: 4.6, monthlySalary: 25_000_000, allowance: 2_000_000),
            FullTimeEmployee(id: "E002", name: "Phạm Bảo", department: "Quality", position: "QA Engineer",
                             hireDate: yearsAgo(2), performanceRating: 4.1, monthlySalary: 18_000_000, allowance: 1_500_000),
            PartTimeEmployee(id: "E003", name: "Trần Đông", department: "Engineering", position: "Intern Developer",
                             hireDate: yearsAgo(1), performanceRating: 4.7, hourlyRate: 80_000),
            PartTimeEmployee(id: "E004", name: "Hạ Cẩm", department: "Design", position: "UI Designer",
                             hireDate: yearsAgo(1), performanceRating: 3.8, hourlyRate: 120_000),
            ContractEmployee(id: "E005", name: "Cao Khánh", department: "Consulting", position: "Business Consultant",
                             hireDate: yearsAgo(1), performanceRating: 4.8, contractModel: .fixedMonthly, fixedMonthlyAmount: 20_000_000),
            ContractEmployee(id: "E006", name: "Lê Ninh", department: "Engineering", position: "Mobile Contractor",
                             hireDate: yearsAgo(1), performanceRating: 4.6, contractModel: .milestoneBased)
        ]
        for e in list { try? addEmployee(e) }

        // Giờ làm tháng trước
        if let p = employee(withID: "E003") as? PartTimeEmployee {
            for d in [3, 4, 5, 10, 11, 12, 17, 18, 19] { try? p.recordHours(6, on: prev.date(day: d), by: admin) }
            try? p.recordHours(5.5, on: cur.date(day: 1), by: admin)
            try? p.recordHours(6, on: cur.date(day: 2), by: admin)
        }
        if let p = employee(withID: "E004") as? PartTimeEmployee {
            for d in [6, 7, 13, 14, 20] { try? p.recordHours(8, on: prev.date(day: d), by: admin) }
            try? p.recordHours(4, on: cur.date(day: 1), by: admin)
        }
        // Milestones
        if let c = employee(withID: "E006") as? ContractEmployee {
            try? c.addMilestone(title: "API design", amount: 15_000_000, by: admin)
            try? c.addMilestone(title: "Mobile prototype", amount: 20_000_000, by: admin)
            try? c.addMilestone(title: "Release 1.0", amount: 30_000_000, by: admin)
            if c.milestones.count == 3 {
                try? c.approveMilestone(id: c.milestones[0].id, in: prev, by: admin)
            }
        }
        // Duyệt lương tháng trước + 1 correction mẫu
        for e in employees { _ = try? e.approvePayment(for: prev, by: admin) }
        try? employee(withID: "E001")?.submitCorrection(for: prev, adjustment: 500_000,
                                                         reason: "Missed transport allowance", by: admin)
        if let c = employee(withID: "E006") as? ContractEmployee, c.milestones.count == 3 {
            try? c.approveMilestone(id: c.milestones[1].id, in: cur, by: admin)
        }
        currentRole = .hrStaff
    }
}

extension PayrollManager {
    static func preview() -> PayrollManager { PayrollManager(sample: true) }
}
