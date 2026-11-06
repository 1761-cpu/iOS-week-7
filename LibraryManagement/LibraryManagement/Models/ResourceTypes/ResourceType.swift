import Foundation

// MARK: - Supporting types
enum ResourceType: String, CaseIterable, Identifiable {
    case book = "Books"
    case journal = "Journals"
    case digital = "Digital"
    var id: String { rawValue }
}

struct InfoItem: Identifiable {
    let id = UUID()
    let label: String
    let value: String
}

/// Một lượt mượn / truy cập đang diễn ra
struct Loan: Identifiable {
    let id = UUID()
    let memberID: String
    let borrowDate: Date
    let dueDate: Date
    let depositPaid: Double
    let accessFeePaid: Double
}

struct ReturnReceipt {
    let lateDays: Int
    let lateFee: Double
    let depositRefunded: Double
    let amountDue: Double      // số tiền phạt vượt quá tiền cọc
}

// MARK: - Base class
/// Trạng thái mượn (`loans`) chỉ được thay đổi qua `borrow` / `giveBack` (private(set)).
class LibraryResource: Identifiable {
    // MARK: Stored properties
    let id: String
    private(set) var title: String
    private(set) var publicationYear: Int
    private(set) var loans: [Loan] = []          // KHÔNG thể sửa trực tiếp từ bên ngoài

    init(id: String, title: String, publicationYear: Int) {
        self.id = id
        self.title = title
        self.publicationYear = publicationYear
    }

    // MARK: Policy hooks (lớp con override)
    var category: ResourceType { .book }
    var typeName: String { "Resource" }
    var icon: String { "books.vertical.fill" }
    var capacity: Int { 1 }                       // số người dùng đồng thời
    var baseLoanDays: Int { 14 }
    var depositAmount: Double { 0 }               // tiền cọc (hoàn lại)
    var accessFee: Double { 0 }                   // phí truy cập (không hoàn)
    var lateFeePerDay: Double { 0 }
    var isBorrowable: Bool { true }
    var restrictionReason: String { "" }
    var actionVerb: String { "Borrow" }
    var returnVerb: String { "Return" }
    var searchableText: String { "" }

    var availabilityText: String {
        if capacity > 1 { return "\(availableCopies)/\(capacity) seats free" }
        return isAvailable ? "Available" : "Borrowed"
    }

    var detailRows: [InfoItem] {
        [InfoItem(label: "Type", value: typeName),
         InfoItem(label: "Published", value: String(publicationYear))]
    }

    // MARK: Computed properties
    var isAvailable: Bool { loans.count < capacity }
    var availableCopies: Int { max(0, capacity - loans.count) }

    // MARK: Policy helpers
    func loanDays(for member: Member) -> Int {
        max(1, Int((Double(baseLoanDays) * member.role.loanMultiplier).rounded()))
    }

    func calculateLateFee(daysLate: Int) -> Double {
        Double(max(0, daysLate)) * lateFeePerDay
    }

    func lateDays(for loan: Loan, on date: Date) -> Int {
        let cal = Calendar.current
        let d = cal.dateComponents([.day], from: cal.startOfDay(for: loan.dueDate), to: cal.startOfDay(for: date)).day ?? 0
        return max(0, d)
    }

    /// Hook kiểm tra điều kiện mượn. Lớp con có thể override và gọi `try super.validateBorrow`.
    func validateBorrow(by member: Member, on date: Date) throws {
        guard isBorrowable else {
            throw LibraryError.notBorrowable(title: title, reason: restrictionReason)
        }
        guard !loans.contains(where: { $0.memberID == member.id }) else {
            throw LibraryError.duplicateLoan(title)
        }
        guard isAvailable else { throw LibraryError.notAvailable(title) }
    }

    // MARK: State-changing operations (duy nhất 2 cách đổi trạng thái)
    final func borrow(by member: Member, on date: Date = Date()) throws -> Loan {
        try validateBorrow(by: member, on: date)
        let due = Calendar.current.date(byAdding: .day, value: loanDays(for: member), to: date) ?? date
        let loan = Loan(memberID: member.id, borrowDate: date, dueDate: due,
                        depositPaid: depositAmount, accessFeePaid: accessFee)
        loans.append(loan)
        return loan
    }

    final func giveBack(memberID: String, on date: Date = Date()) throws -> ReturnReceipt {
        guard let index = loans.firstIndex(where: { $0.memberID == memberID }) else {
            throw LibraryError.notBorrowedByMember(title)
        }
        let loan = loans[index]
        let cal = Calendar.current
        guard cal.startOfDay(for: date) >= cal.startOfDay(for: loan.borrowDate) else {
            throw LibraryError.invalidReturnDate
        }
        let days = lateDays(for: loan, on: date)
        let fee = calculateLateFee(daysLate: days)
        let refund = max(0, loan.depositPaid - fee)
        let due = max(0, fee - loan.depositPaid)
        loans.remove(at: index)
        return ReturnReceipt(lateDays: days, lateFee: fee, depositRefunded: refund, amountDue: due)
    }

    func isOverdue(_ loan: Loan, on date: Date = Date()) -> Bool {
        lateDays(for: loan, on: date) > 0
    }
}
