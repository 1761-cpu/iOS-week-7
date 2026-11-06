import Foundation

struct WorkLog: Identifiable {
    let id = UUID()
    let date: Date
    let hours: Double
}

final class PartTimeEmployee: Employee {
    static let maxMonthlyHours = 120.0
    static let maxHoursPerEntry = 24.0

    private(set) var hourlyRate: Double
    private(set) var workLogs: [WorkLog] = []

    init(id: String, name: String, department: String, position: String, hireDate: Date,
         performanceRating: Double = 3.0, hourlyRate: Double) {
        self.hourlyRate = hourlyRate
        super.init(id: id, name: name, department: department, position: position,
                   hireDate: hireDate, performanceRating: performanceRating)
    }

    override var employmentType: EmploymentType { .partTime }
    override var typeName: String { "Part-time" }
    override var icon: String { "clock.fill" }
    override var bonusPolicyText: String { "Rating ≥ 4.5: +10% of hourly pay" }

    override func performanceBonusRate(for rating: Double) -> Double { rating >= 4.5 ? 0.10 : 0 }

    func hours(in month: PayMonth) -> Double {
        workLogs.filter { month.contains($0.date) }.reduce(0) { $0 + $1.hours }
    }

    func logs(in month: PayMonth) -> [WorkLog] {
        workLogs.filter { month.contains($0.date) }.sorted { $0.date < $1.date }
    }

    override func compensationLines(for month: PayMonth) -> [PayLine] {
        let h = hours(in: month)
        let base = (h * hourlyRate).rounded()
        var lines = [PayLine(label: "Hours worked (\(String(format: "%.1f", h)) h × \(hourlyRate.vnd))", amount: base)]
        if let b = bonusLine(base: base) { lines.append(b) }
        return lines
    }

    override var compensationRows: [InfoItem] {
        [InfoItem(label: "Hourly rate", value: hourlyRate.vnd),
         InfoItem(label: "Monthly hour limit", value: "\(Int(Self.maxMonthlyHours)) h"),
         InfoItem(label: "Bonus policy", value: bonusPolicyText)]
    }

    /// Ghi nhận giờ làm: không âm, tối đa 24h/lần, không vượt giới hạn tháng, không ghi vào tháng đã duyệt.
    func recordHours(_ hours: Double, on date: Date, by role: UserRole) throws {
        try authorize(role, .editInfo, action: "Record working hours")
        guard hours.isFinite, hours >= 0, hours <= Self.maxHoursPerEntry else {
            throw PayrollError.invalidHours(hours)
        }
        let month = PayMonth(date: date)
        try ensureMonthOpen(month)
        let total = self.hours(in: month) + hours
        guard total <= Self.maxMonthlyHours else {
            throw PayrollError.monthlyHoursExceeded(limit: Self.maxMonthlyHours, attempted: total)
        }
        workLogs.append(WorkLog(date: date, hours: hours))
    }

    func setHourlyRate(_ rate: Double, by role: UserRole) throws {
        try authorize(role, .editCompensation, action: "Change hourly rate")
        guard rate.isFinite, rate > 0 else { throw PayrollError.invalidAmount("Hourly rate") }
        hourlyRate = rate
    }
}
