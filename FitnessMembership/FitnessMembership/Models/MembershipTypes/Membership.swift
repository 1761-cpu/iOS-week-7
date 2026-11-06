import Foundation

// MARK: - Base class
/// Số dư đã trả, trạng thái, buổi tập... đều `private(set)` — chỉ đổi qua phương thức có kiểm tra.
class Membership: Identifiable {
    // MARK: Stored properties
    let id: String
    let activationDate: Date
    private(set) var memberName: String
    private(set) var phone: String
    private(set) var status: MembershipStatus = .active
    private(set) var unitFee: Double                 // phí tháng (Basic/Premium) hoặc giá mỗi buổi (PT)
    private(set) var amountPaid: Double = 0
    private(set) var promotion: Promotion?
    private(set) var temporaryUpgradeUntil: Date?
    private(set) var pendingRequest: ChangeRequest?
    private(set) var checkIns: [CheckInRecord] = []
    private(set) var billingStart: Date

    init(id: String, memberName: String, phone: String, activationDate: Date, unitFee: Double) {
        self.id = id
        self.memberName = memberName
        self.phone = phone
        self.activationDate = activationDate
        self.unitFee = unitFee
        self.billingStart = activationDate
    }

    // MARK: Policy hooks (lớp con override)
    var type: MembershipType { .basic }
    var typeName: String { "Membership" }
    var icon: String { "figure.walk" }
    var feeLabel: String { "Monthly fee" }
    var facilities: [Facility] { [] }
    var accessWindow: AccessWindow { AccessWindow(openHour: 6, closeHour: 21) }
    var supportsTemporaryUpgrade: Bool { false }
    var benefitRows: [InfoItem] { [] }
    var searchableText: String { "" }
    func chargeLines() -> [ChargeLine] { [] }
    func resetPeriodUsage() {}

    // MARK: Computed properties
    var hasTemporaryUpgrade: Bool {
        guard let d = temporaryUpgradeUntil else { return false }
        return d >= Date()
    }

    var activePromotion: Promotion? {
        guard let p = promotion, p.isValid() else { return nil }
        return p
    }

    final var breakdown: ChargeBreakdown {
        let lines = chargeLines()
        let subtotal = lines.reduce(0) { $0 + $1.amount }
        var discount = 0.0
        if let p = activePromotion { discount = (subtotal * p.percentOff / 100).rounded() }
        let total = subtotal - discount
        return ChargeBreakdown(lines: lines, promotion: activePromotion, subtotal: subtotal,
                               discount: discount, total: total, paid: amountPaid,
                               outstanding: max(0, total - amountPaid))
    }

    final var estimatedCharges: Double { breakdown.total }
    final var outstanding: Double { breakdown.outstanding }

    var detailRows: [InfoItem] {
        [InfoItem(label: "Membership ID", value: id),
         InfoItem(label: "Plan", value: typeName),
         InfoItem(label: "Member", value: memberName),
         InfoItem(label: "Phone", value: phone),
         InfoItem(label: "Activated", value: activationDate.short),
         InfoItem(label: "Billing since", value: billingStart.short)]
    }

    // MARK: Guards (dùng chung cho lớp con)
    final func authorize(_ role: UserRole, _ permission: Permission, action: String) throws {
        guard role.can(permission) else {
            throw MembershipError.unauthorized(action: action, role: role.rawValue)
        }
    }

    final func ensureUsable() throws {
        switch status {
        case .active: return
        case .suspended: throw MembershipError.membershipSuspended(memberName)
        case .expired: throw MembershipError.membershipExpired(memberName)
        }
    }

    // MARK: Staff operations
    final func updateDetails(name: String, phone: String, by role: UserRole) throws {
        try authorize(role, .editDetails, action: "Update membership details")
        let n = name.trimmingCharacters(in: .whitespaces)
        let p = phone.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty else { throw MembershipError.emptyField("Member name") }
        guard !p.isEmpty else { throw MembershipError.emptyField("Phone") }
        memberName = n
        self.phone = p
    }

    final func setStatus(_ new: MembershipStatus, by role: UserRole) throws {
        try authorize(role, .changeStatus, action: "Change membership status")
        guard new != status else { throw MembershipError.statusUnchanged(new.rawValue) }
        if new == .expired || status == .expired {
            try authorize(role, .manageBilling, action: "Expire or reactivate an expired membership")
        }
        if status == .expired && new == .active {
            guard outstanding == 0 else { throw MembershipError.cannotReactivateWithBalance(outstanding) }
        }
        status = new
    }

    /// Phí chỉ đổi qua đây (Manager). Không có setter công khai.
    final func updateFee(to newFee: Double, by role: UserRole) throws {
        try authorize(role, .manageBilling, action: "Change membership fee")
        guard newFee.isFinite, newFee > 0 else { throw MembershipError.invalidAmount(feeLabel) }
        unitFee = newFee
    }

    final func recordPayment(_ amount: Double, by role: UserRole) throws {
        try authorize(role, .recordPayment, action: "Record payment")
        guard amount.isFinite, amount > 0 else { throw MembershipError.invalidAmount("Payment") }
        let due = outstanding
        guard amount <= due else { throw MembershipError.overpayment(maxDue: due) }
        amountPaid += amount
    }

    final func applyPromotion(_ p: Promotion, by role: UserRole) throws {
        try authorize(role, .applyPromotion, action: "Apply promotion")
        guard p.isValid() else { throw MembershipError.promotionExpired(p.code) }
        guard p.isEligible(for: type) else { throw MembershipError.promotionNotEligible(code: p.code, plan: typeName) }
        guard promotion != p else { throw MembershipError.promotionAlreadyApplied(p.code) }
        promotion = p
    }

    final func removePromotion(by role: UserRole) throws {
        try authorize(role, .applyPromotion, action: "Remove promotion")
        promotion = nil
    }

    final func grantTemporaryUpgrade(days: Int, by role: UserRole) throws {
        try authorize(role, .applyPromotion, action: "Grant temporary upgrade")
        try applyUpgrade(days: days)
    }

    private func applyUpgrade(days: Int) throws {
        guard supportsTemporaryUpgrade else { throw MembershipError.upgradeNotAvailable(typeName) }
        try ensureUsable()
        guard (1...30).contains(days) else { throw MembershipError.invalidUpgradeDays(days) }
        guard !hasTemporaryUpgrade else { throw MembershipError.upgradeAlreadyActive }
        temporaryUpgradeUntil = Calendar.current.date(byAdding: .day, value: days, to: Date())
    }

    final func startNewBillingPeriod(by role: UserRole) throws {
        try authorize(role, .changeStatus, action: "Start a new billing period")
        guard status == .active else { throw MembershipError.periodRequiresActive }
        guard outstanding == 0 else { throw MembershipError.outstandingBalance(outstanding) }
        amountPaid = 0
        billingStart = Date()
        resetPeriodUsage()
    }

    // MARK: Check-in
    @discardableResult
    final func checkIn(at date: Date = Date(), facility: Facility, by role: UserRole) throws -> CheckInRecord {
        try authorize(role, .useFacilities, action: "Check in")
        try ensureUsable()                        // suspended / expired → từ chối
        guard facilities.contains(facility) else {
            throw MembershipError.facilityNotIncluded(facility: facility.rawValue, plan: typeName)
        }
        guard accessWindow.contains(date) else {
            throw MembershipError.outsideAccessHours(accessWindow.text)
        }
        let rec = CheckInRecord(date: date, facility: facility)
        checkIns.append(rec)
        return rec
    }

    // MARK: Change requests (hội viên gửi, nhân viên duyệt)
    final func submitRequest(_ kind: RequestKind, by role: UserRole) throws {
        try authorize(role, .requestChange, action: "Submit a change request")
        guard pendingRequest == nil else { throw MembershipError.requestPending }
        switch kind {
        case .freeze:
            guard status == .active else { throw MembershipError.requestNotApplicable("only active memberships can be frozen") }
        case .unfreeze:
            guard status == .suspended else { throw MembershipError.requestNotApplicable("only suspended memberships can be reactivated") }
        case .trialPremium:
            guard supportsTemporaryUpgrade else { throw MembershipError.upgradeNotAvailable(typeName) }
            guard !hasTemporaryUpgrade else { throw MembershipError.upgradeAlreadyActive }
        }
        pendingRequest = ChangeRequest(kind: kind, date: Date())
    }

    final func resolveRequest(approve: Bool, by role: UserRole) throws {
        try authorize(role, .changeStatus, action: "Resolve change request")
        guard let req = pendingRequest else { throw MembershipError.noPendingRequest }
        if approve {
            switch req.kind {
            case .freeze: status = .suspended
            case .unfreeze: status = .active
            case .trialPremium: try applyUpgrade(days: 7)
            }
        }
        pendingRequest = nil
    }
}
