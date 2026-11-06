import Foundation

// MARK: - Base class
/// Trạng thái, phí gốc, dịch vụ, khuyến mãi đều `private(set)` — chỉ đổi qua phương thức có kiểm tra.
class Appointment: Identifiable {
    // MARK: Stored properties
    let id: String
    let pet: Pet
    let createdDate: Date
    private(set) var scheduledDate: Date
    private(set) var status: AppointmentStatus
    private(set) var notes: String
    private(set) var baseFee: Double
    private(set) var promotion: Promotion?
    private(set) var services: [ServiceItem] = []
    private(set) var pendingRequest: ChangeRequest?
    private(set) var amendments: [Amendment] = []
    private(set) var completedDate: Date?

    init(id: String, pet: Pet, scheduledDate: Date, baseFee: Double, notes: String = "",
         initialStatus: AppointmentStatus = .booked, createdDate: Date = Date()) {
        self.id = id
        self.pet = pet
        self.scheduledDate = scheduledDate
        self.baseFee = baseFee
        self.notes = notes
        self.status = initialStatus
        self.createdDate = createdDate
    }

    // MARK: Policy hooks (lớp con override)
    var type: AppointmentType { .routine }
    var typeName: String { "Appointment" }
    var icon: String { "stethoscope" }
    var feeLabel: String { "Base fee" }
    var priority: Int { 1 }                          // 0 = cao nhất
    var allowedCheckInStatuses: Set<AppointmentStatus> { [.confirmed] }
    var requiresSameDayCheckIn: Bool { true }
    var allowsReschedule: Bool { true }
    var typeSpecificActions: [String] { [] }
    var typeSpecificRows: [InfoItem] { [] }
    var searchableText: String { "" }
    func chargeLines() -> [ChargeLine] { [] }
    func validateReady() throws {}                  // điều kiện bổ sung trước confirm / check-in
    func didComplete() {}
    func didReopen() {}

    // MARK: Computed properties
    var owner: Owner { pet.owner }

    final var chargesLocked: Bool { status == .confirmed || status == .checkedIn || status == .completed }
    final var isClosed: Bool { status == .completed || status == .cancelled }

    var activePromotion: Promotion? {
        guard let p = promotion, p.isValid() else { return nil }
        return p
    }

    final var breakdown: ChargeBreakdown {
        let base = chargeLines()
        let svc = services.map { ChargeLine(label: "Service: \($0.name)", amount: $0.price) }
        let subtotal = (base + svc).reduce(0) { $0 + $1.amount }
        let svcTotal = svc.reduce(0) { $0 + $1.amount }
        var discount = 0.0
        if let p = activePromotion {
            let basis = (p.scope == .total) ? subtotal : svcTotal
            discount = (basis * p.percentOff / 100).rounded()
        }
        return ChargeBreakdown(lines: base + svc, promotion: activePromotion,
                               subtotal: subtotal, discount: discount, total: subtotal - discount)
    }

    final var estimatedCharges: Double { status == .cancelled ? 0 : breakdown.total }

    var detailRows: [InfoItem] {
        var rows = [InfoItem(label: "Appointment ID", value: id),
                    InfoItem(label: "Type", value: typeName),
                    InfoItem(label: "Scheduled", value: scheduledDate.dateTimeText),
                    InfoItem(label: "Status", value: status.rawValue)]
        rows += typeSpecificRows
        rows.append(InfoItem(label: "Notes", value: notes.isEmpty ? "—" : notes))
        return rows
    }

    /// Hành động khả dụng — hiển thị khác nhau theo loại & trạng thái
    final var availableActions: [String] {
        var list: [String]
        switch status {
        case .booked:
            list = ["Confirm booking", "Add services", "Cancel"]
            if allowsReschedule { list.append("Reschedule") }
            if allowedCheckInStatuses.contains(.booked) { list.append("Priority check-in") }
        case .confirmed:
            list = ["Check in", "Add services", "Cancel"]
            if allowsReschedule { list.append("Reschedule") }
        case .checkedIn:
            list = ["Add services", "Complete visit"]
        case .completed:
            list = ["View invoice", "Amend visit (Manager)"]
        case .cancelled:
            list = []
        }
        return list + (isClosed ? [] : typeSpecificActions)
    }

    // MARK: Guards (dùng chung cho lớp con)
    final func authorize(_ role: UserRole, _ permission: Permission, action: String) throws {
        guard role.can(permission) else {
            throw VetError.unauthorized(action: action, role: role.rawValue)
        }
    }

    /// Chặn khi đã hủy / hoàn tất
    final func ensureNotClosed(_ action: String) throws {
        switch status {
        case .cancelled: throw VetError.appointmentCancelled(action)
        case .completed: throw VetError.completedVisitLocked(action)
        default: return
        }
    }

    /// Chặn khi đã hủy / hoàn tất / đang khám
    final func ensureEditable(_ action: String) throws {
        try ensureNotClosed(action)
        if status == .checkedIn { throw VetError.visitInProgress(action) }
    }

    // MARK: Reception operations
    final func updateNotes(_ text: String, by role: UserRole) throws {
        try authorize(role, .editBooking, action: "Update appointment notes")
        try ensureNotClosed("modified")
        notes = text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    final func confirm(by role: UserRole) throws {
        try authorize(role, .editBooking, action: "Confirm appointment")
        try ensureNotClosed("confirmed")
        guard status == .booked else {
            throw VetError.invalidStatus(expected: AppointmentStatus.booked.rawValue, actual: status.rawValue)
        }
        try validateReady()
        status = .confirmed          // từ đây phí gốc & khuyến mãi bị khóa
    }

    final func checkIn(at date: Date = Date(), by role: UserRole) throws {
        try authorize(role, .editBooking, action: "Check in")
        switch status {
        case .cancelled: throw VetError.appointmentCancelled("checked in")
        case .completed: throw VetError.completedVisitLocked("checked in")
        case .checkedIn: throw VetError.invalidStatus(expected: AppointmentStatus.confirmed.rawValue, actual: status.rawValue)
        default: break
        }
        guard allowedCheckInStatuses.contains(status) else { throw VetError.notConfirmed }
        if requiresSameDayCheckIn {
            guard Calendar.current.isDate(date, inSameDayAs: scheduledDate) else { throw VetError.notScheduledToday }
        }
        try validateReady()
        status = .checkedIn
    }

    final func complete(by role: UserRole) throws {
        try authorize(role, .completeVisit, action: "Complete visit")
        try ensureNotClosed("completed again")
        guard status == .checkedIn else { throw VetError.notCheckedIn }
        status = .completed
        completedDate = Date()
        didComplete()
    }

    final func cancel(by role: UserRole) throws {
        try authorize(role, .editBooking, action: "Cancel appointment")
        try ensureEditable("cancelled")
        status = .cancelled
        pendingRequest = nil
    }

    final func reschedule(to newDate: Date, by role: UserRole) throws {
        try authorize(role, .editBooking, action: "Reschedule appointment")
        try ensureEditable("rescheduled")          // đã hoàn tất → phải qua amendment
        guard allowsReschedule else { throw VetError.rescheduleNotAllowed(typeName) }
        guard newDate > Date() else { throw VetError.dateInPast }
        scheduledDate = newDate
    }

    final func addService(_ service: ServiceItem, by role: UserRole) throws {
        try authorize(role, .addService, action: "Add a service")
        try ensureNotClosed("modified")
        guard !services.contains(service) else { throw VetError.serviceAlreadyAdded(service.name) }
        services.append(service)
    }

    // MARK: Pricing (khóa sau khi xác nhận)
    final func updateBaseFee(to newFee: Double, by role: UserRole) throws {
        try authorize(role, .changeFees, action: "Change appointment fee")
        try ensureNotClosed("modified")
        guard !chargesLocked else { throw VetError.chargesLocked }
        guard newFee.isFinite, newFee > 0 else { throw VetError.invalidAmount(feeLabel) }
        baseFee = newFee
    }

    final func applyPromotion(_ p: Promotion, by role: UserRole) throws {
        try authorize(role, .editBooking, action: "Apply promotion")
        try ensureNotClosed("modified")
        guard !chargesLocked else { throw VetError.chargesLocked }
        guard p.isValid() else { throw VetError.promotionExpired(p.code) }
        guard p.isEligible(for: type) else { throw VetError.promotionNotEligible(code: p.code, type: typeName) }
        guard promotion != p else { throw VetError.promotionAlreadyApplied(p.code) }
        promotion = p
    }

    final func removePromotion(by role: UserRole) throws {
        try authorize(role, .editBooking, action: "Remove promotion")
        try ensureNotClosed("modified")
        guard !chargesLocked else { throw VetError.chargesLocked }
        promotion = nil
    }

    // MARK: Amendment procedure (mở lại lượt khám đã hoàn tất)
    final func reopenCompletedVisit(reason: String, by role: UserRole) throws {
        try authorize(role, .amendCompleted, action: "Amend a completed visit")
        guard status == .completed else {
            throw VetError.invalidStatus(expected: AppointmentStatus.completed.rawValue, actual: status.rawValue)
        }
        let r = reason.trimmingCharacters(in: .whitespaces)
        guard !r.isEmpty else { throw VetError.reasonRequired }
        amendments.append(Amendment(reason: r, date: Date()))
        status = .confirmed
        completedDate = nil
        didReopen()
    }

    // MARK: Change requests (chủ nuôi gửi, lễ tân duyệt)
    final func submitRequest(_ kind: ChangeRequestKind, by role: UserRole) throws {
        try authorize(role, .requestChange, action: "Submit a change request")
        try ensureEditable("changed")
        guard pendingRequest == nil else { throw VetError.requestPending }
        if case .reschedule(let d) = kind {
            guard allowsReschedule else { throw VetError.rescheduleNotAllowed(typeName) }
            guard d > Date() else { throw VetError.dateInPast }
        }
        pendingRequest = ChangeRequest(kind: kind, date: Date())
    }

    final func resolveRequest(approve: Bool, by role: UserRole) throws {
        try authorize(role, .editBooking, action: "Resolve change request")
        guard let req = pendingRequest else { throw VetError.noPendingRequest }
        if approve {
            switch req.kind {
            case .cancel: try cancel(by: role)
            case .reschedule(let d): try reschedule(to: d, by: role)
            }
        }
        pendingRequest = nil
    }
}
