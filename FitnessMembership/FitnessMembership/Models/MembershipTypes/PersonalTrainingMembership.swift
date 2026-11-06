import Foundation

final class PersonalTrainingMembership: Membership {
    let packageSessions: Int
    private(set) var coachName: String
    private(set) var addedSessions = 0
    private(set) var sessionsAttended = 0

    init(id: String, memberName: String, phone: String, activationDate: Date,
         pricePerSession: Double, packageSessions: Int, coachName: String) {
        self.packageSessions = packageSessions
        self.coachName = coachName
        super.init(id: id, memberName: memberName, phone: phone, activationDate: activationDate, unitFee: pricePerSession)
    }

    override var type: MembershipType { .personalTraining }
    override var typeName: String { "Personal Training" }
    override var icon: String { "figure.strengthtraining.traditional" }
    override var feeLabel: String { "Price per session" }
    override var facilities: [Facility] { [.gymFloor, .cardio, .locker, .trainingZone] }
    override var searchableText: String { coachName.lowercased() }

    var sessionsPurchased: Int { packageSessions + addedSessions }
    var sessionsRemaining: Int { sessionsPurchased - sessionsAttended }   // luôn ≥ 0 nhờ validation

    override func chargeLines() -> [ChargeLine] {
        var lines = [ChargeLine(label: "Package: \(packageSessions) sessions × \(unitFee.vnd)",
                                amount: Double(packageSessions) * unitFee)]
        if addedSessions > 0 {
            lines.append(ChargeLine(label: "Added: \(addedSessions) sessions × \(unitFee.vnd)",
                                    amount: Double(addedSessions) * unitFee))
        }
        return lines
    }

    override var benefitRows: [InfoItem] {
        [InfoItem(label: "Coach", value: coachName),
         InfoItem(label: "Sessions remaining", value: "\(sessionsRemaining) of \(sessionsPurchased)"),
         InfoItem(label: "Sessions attended", value: "\(sessionsAttended)"),
         InfoItem(label: "Opening hours", value: accessWindow.text)]
    }

    override func resetPeriodUsage() {
        addedSessions = 0
        sessionsAttended = 0
    }

    /// Ghi nhận 1 buổi tập: số dư buổi không bao giờ âm.
    func attendSession(by role: UserRole) throws {
        try authorize(role, .adjustSessions, action: "Record an attended session")
        try ensureUsable()
        guard sessionsRemaining > 0 else { throw MembershipError.insufficientSessions }
        sessionsAttended += 1
    }

    /// Thêm buổi trong kỳ thanh toán → tăng phí.
    func addSessions(_ count: Int, by role: UserRole) throws {
        try authorize(role, .adjustSessions, action: "Add sessions")
        try ensureUsable()
        guard (1...20).contains(count) else { throw MembershipError.invalidSessionCount(count) }
        addedSessions += count
    }
}
