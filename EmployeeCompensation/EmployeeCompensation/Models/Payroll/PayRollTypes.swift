import Foundation

// MARK: - Loại hình làm việc
enum EmploymentType: String, CaseIterable, Identifiable {
    case fullTime = "Full-time"
    case partTime = "Part-time"
    case contract = "Contract"
    var id: String { rawValue }
}

// MARK: - Phân quyền
enum Permission { case editInfo, editCompensation, approvePayment }

enum UserRole: String, CaseIterable, Identifiable {
    case hrStaff = "HR Staff"
    case payrollAdmin = "Payroll Admin"
    case viewer = "Viewer"
    var id: String { rawValue }

    func can(_ permission: Permission) -> Bool {
        switch self {
        case .payrollAdmin: return true
        case .hrStaff: return permission == .editInfo
        case .viewer: return false
        }
    }
}

// MARK: - Kỳ lương (tháng)
struct PayMonth: Hashable, Comparable, Identifiable {
    let year: Int
    let month: Int
    var id: String { String(format: "%04d-%02d", year, month) }

    init(year: Int, month: Int) {
        self.year = year
        self.month = month
    }

    init(date: Date) {
        let c = Calendar.current.dateComponents([.year, .month], from: date)
        self.year = c.year ?? 2000
        self.month = c.month ?? 1
    }

    static var current: PayMonth { PayMonth(date: Date()) }

    var firstDay: Date { Calendar.current.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date() }
    var previous: PayMonth { PayMonth(date: Calendar.current.date(byAdding: .month, value: -1, to: firstDay) ?? firstDay) }
    var next: PayMonth { PayMonth(date: Calendar.current.date(byAdding: .month, value: 1, to: firstDay) ?? firstDay) }
    var title: String { firstDay.formatted(.dateTime.month(.wide).year()) }

    func date(day: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: day - 1, to: firstDay) ?? firstDay
    }
    func contains(_ date: Date) -> Bool { PayMonth(date: date) == self }

    static func < (a: PayMonth, b: PayMonth) -> Bool { (a.year, a.month) < (b.year, b.month) }
}

// MARK: - Dữ liệu hiển thị / sổ lương
struct InfoItem: Identifiable {
    let id = UUID()
    let label: String
    let value: String
}

struct PayLine: Identifiable {
    let id = UUID()
    let label: String
    let amount: Double
}

/// Khoản lương đã duyệt — bất biến (snapshot các dòng lương tại thời điểm duyệt)
struct PaymentRecord: Identifiable {
    let id = UUID()
    let month: PayMonth
    let lines: [PayLine]
    let amount: Double
    let approvedOn: Date
}

/// Điều chỉnh sau khi duyệt (correction procedure) — không sửa record gốc
struct Correction: Identifiable {
    let id = UUID()
    let month: PayMonth
    let adjustment: Double
    let reason: String
    let date: Date
}

struct PaySummary: Identifiable {
    var id: String { employeeID }
    let employeeID: String
    let employeeName: String
    let department: String
    let typeName: String
    let type: EmploymentType
    let month: PayMonth
    let lines: [PayLine]
    let corrections: [Correction]
    let netPayable: Double
    let isApproved: Bool
}
