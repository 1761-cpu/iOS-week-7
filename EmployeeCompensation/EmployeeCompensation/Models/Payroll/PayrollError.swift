import Foundation

enum PayrollError: LocalizedError {
    case emptyField(String)
    case invalidNumber(String)
    case invalidAmount(String)
    case invalidRating(Double)
    case invalidHours(Double)
    case monthlyHoursExceeded(limit: Double, attempted: Double)
    case unauthorized(action: String, role: String)
    case duplicateEmployee(String)
    case employeeNotFound(String)
    case monthAlreadyApproved(String)
    case monthNotApproved(String)
    case approvedPaymentLocked(String)
    case nothingToPay(String)
    case milestoneNotFound
    case milestoneAlreadyApproved(String)
    case milestoneLocked(String)
    case notMilestoneContract
    case notFixedContract
    case correctionReasonRequired
    case invalidCorrection

    var errorDescription: String? {
        switch self {
        case .emptyField(let f):
            return "\(f) cannot be empty."
        case .invalidNumber(let f):
            return "\(f) must be a number."
        case .invalidAmount(let f):
            return "\(f) is invalid (must be a valid positive amount)."
        case .invalidRating(let r):
            return "Performance rating \(r) must be between 0 and 5."
        case .invalidHours(let h):
            return "Working hours \(h) are invalid: hours cannot be negative and must not exceed 24 per entry."
        case .monthlyHoursExceeded(let limit, let attempted):
            return "Total monthly hours would be \(attempted), above the part-time limit of \(limit)."
        case .unauthorized(let action, let role):
            return "\(role) is not authorized to: \(action)."
        case .duplicateEmployee(let id):
            return "Employee ID \(id) already exists."
        case .employeeNotFound(let id):
            return "Employee with ID \(id) not found."
        case .monthAlreadyApproved(let m):
            return "Payment for \(m) is already approved and locked. Use the correction procedure."
        case .monthNotApproved(let m):
            return "Payment for \(m) has not been approved yet."
        case .approvedPaymentLocked(let m):
            return "The approved payment for \(m) cannot be modified directly. Submit a correction with a reason instead."
        case .nothingToPay(let n):
            return "\(n) has no payable amount for this month."
        case .milestoneNotFound:
            return "Milestone not found."
        case .milestoneAlreadyApproved(let t):
            return "Milestone \"\(t)\" is already approved."
        case .milestoneLocked(let t):
            return "Milestone \"\(t)\" is approved and locked. Use the correction procedure to change a paid amount."
        case .notMilestoneContract:
            return "This contract is not milestone-based."
        case .notFixedContract:
            return "This contract is not a fixed-payment contract."
        case .correctionReasonRequired:
            return "A correction requires a written reason."
        case .invalidCorrection:
            return "Invalid correction: the adjustment must be non-zero and the final amount cannot become negative."
        }
    }
}
