import Foundation

final class PremiumMembership: Membership {
    static let perkFacilities: [Facility] = [.gymFloor, .cardio, .locker, .pool, .sauna, .groupStudio]
    static let perkWindow = AccessWindow(openHour: 5, closeHour: 23)

    let monthlyClassLimit: Int
    private(set) var classesUsed = 0
    private(set) var bookedClasses: [String] = []

    init(id: String, memberName: String, phone: String, activationDate: Date,
         monthlyFee: Double, monthlyClassLimit: Int = 8) {
        self.monthlyClassLimit = monthlyClassLimit
        super.init(id: id, memberName: memberName, phone: phone, activationDate: activationDate, unitFee: monthlyFee)
    }

    override var type: MembershipType { .premium }
    override var typeName: String { "Premium" }
    override var icon: String { "star.circle.fill" }
    override var facilities: [Facility] { Self.perkFacilities }
    override var accessWindow: AccessWindow { Self.perkWindow }
    override var searchableText: String { bookedClasses.joined(separator: " ").lowercased() }

    var classesRemaining: Int { max(0, monthlyClassLimit - classesUsed) }

    override func chargeLines() -> [ChargeLine] {
        [ChargeLine(label: "Monthly fee", amount: unitFee)]
    }

    override var benefitRows: [InfoItem] {
        [InfoItem(label: "Access", value: "All facilities incl. pool & sauna"),
         InfoItem(label: "Extended hours", value: accessWindow.text),
         InfoItem(label: "Group classes", value: "\(classesUsed)/\(monthlyClassLimit) used this month")]
    }

    override func resetPeriodUsage() {
        classesUsed = 0
        bookedClasses = []
    }

    /// Quyền lợi có giới hạn sử dụng theo tháng
    func bookGroupClass(named name: String, by role: UserRole) throws {
        try authorize(role, .useFacilities, action: "Book a group class")
        try ensureUsable()
        let n = name.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty else { throw MembershipError.emptyField("Class name") }
        guard classesUsed < monthlyClassLimit else {
            throw MembershipError.monthlyLimitReached(benefit: "Group classes", limit: monthlyClassLimit)
        }
        classesUsed += 1
        bookedClasses.append(n)
    }
}
