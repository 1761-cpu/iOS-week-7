import Foundation

enum MembershipError: LocalizedError {
    case emptyField(String)
    case invalidNumber(String)
    case invalidAmount(String)
    case invalidSessionCount(Int)
    case invalidUpgradeDays(Int)
    case unauthorized(action: String, role: String)
    case duplicateMembership(String)
    case membershipNotFound(String)
    case membershipSuspended(String)
    case membershipExpired(String)
    case facilityNotIncluded(facility: String, plan: String)
    case outsideAccessHours(String)
    case monthlyLimitReached(benefit: String, limit: Int)
    case insufficientSessions
    case overpayment(maxDue: Double)
    case statusUnchanged(String)
    case cannotReactivateWithBalance(Double)
    case promotionNotEligible(code: String, plan: String)
    case promotionExpired(String)
    case promotionAlreadyApplied(String)
    case upgradeNotAvailable(String)
    case upgradeAlreadyActive
    case requestPending
    case requestNotApplicable(String)
    case noPendingRequest
    case outstandingBalance(Double)
    case periodRequiresActive

    var errorDescription: String? {
        switch self {
        case .emptyField(let f):
            return "\(f) cannot be empty."
        case .invalidNumber(let f):
            return "\(f) must be a number."
        case .invalidAmount(let f):
            return "\(f) is invalid (must be a positive amount)."
        case .invalidSessionCount(let n):
            return "Session count \(n) is invalid (must be between 1 and 20)."
        case .invalidUpgradeDays(let d):
            return "Upgrade length \(d) days is invalid (must be between 1 and 30)."
        case .unauthorized(let action, let role):
            return "\(role) is not authorized to: \(action)."
        case .duplicateMembership(let id):
            return "Membership ID \(id) already exists."
        case .membershipNotFound(let id):
            return "Membership with ID \(id) not found."
        case .membershipSuspended(let n):
            return "\(n)'s membership is suspended and cannot be used."
        case .membershipExpired(let n):
            return "\(n)'s membership has expired and cannot be used."
        case .facilityNotIncluded(let f, let p):
            return "\(f) is not included in the \(p) plan."
        case .outsideAccessHours(let w):
            return "Check-in is outside the allowed access hours (\(w))."
        case .monthlyLimitReached(let b, let l):
            return "\(b) monthly limit of \(l) has been reached."
        case .insufficientSessions:
            return "No sessions remaining. The session balance cannot become negative."
        case .overpayment(let due):
            return "Payment exceeds the outstanding balance (\(due.vnd))."
        case .statusUnchanged(let s):
            return "The membership is already \(s)."
        case .cannotReactivateWithBalance(let b):
            return "Cannot reactivate an expired membership with an outstanding balance of \(b.vnd)."
        case .promotionNotEligible(let c, let p):
            return "Promotion \(c) is not available for the \(p) plan."
        case .promotionExpired(let c):
            return "Promotion \(c) has expired."
        case .promotionAlreadyApplied(let c):
            return "Promotion \(c) is already applied."
        case .upgradeNotAvailable(let p):
            return "Temporary upgrades are not available for the \(p) plan."
        case .upgradeAlreadyActive:
            return "A temporary upgrade is already active."
        case .requestPending:
            return "There is already a pending change request."
        case .requestNotApplicable(let r):
            return "This request is not applicable now: \(r)."
        case .noPendingRequest:
            return "There is no pending request."
        case .outstandingBalance(let b):
            return "Cannot start a new billing period: outstanding balance is \(b.vnd)."
        case .periodRequiresActive:
            return "Only an active membership can start a new billing period."
        }
    }
}
