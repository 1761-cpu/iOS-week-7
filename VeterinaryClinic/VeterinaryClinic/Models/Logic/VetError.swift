import Foundation

enum VetError: LocalizedError {
    case emptyField(String)
    case invalidNumber(String)
    case invalidAmount(String)
    case unauthorized(action: String, role: String)
    case duplicateAppointment(String)
    case appointmentNotFound(String)
    case appointmentCancelled(String)
    case completedVisitLocked(String)
    case visitInProgress(String)
    case invalidStatus(expected: String, actual: String)
    case notConfirmed
    case notScheduledToday
    case notCheckedIn
    case chargesLocked
    case rescheduleNotAllowed(String)
    case dateInPast
    case vaccineNotSelected
    case vaccineSpeciesMismatch(vaccine: String, species: String)
    case vaccineTooSoon(vaccine: String, nextDate: Date)
    case promotionExpired(String)
    case promotionNotEligible(code: String, type: String)
    case promotionAlreadyApplied(String)
    case serviceAlreadyAdded(String)
    case requestPending
    case noPendingRequest
    case reasonRequired

    var errorDescription: String? {
        switch self {
        case .emptyField(let f):
            return "\(f) cannot be empty."
        case .invalidNumber(let f):
            return "\(f) must be a number."
        case .invalidAmount(let f):
            return "\(f) is invalid (must be a positive amount)."
        case .unauthorized(let action, let role):
            return "\(role) is not authorized to: \(action)."
        case .duplicateAppointment(let id):
            return "Appointment ID \(id) already exists."
        case .appointmentNotFound(let id):
            return "Appointment with ID \(id) not found."
        case .appointmentCancelled(let a):
            return "A cancelled appointment cannot be \(a)."
        case .completedVisitLocked(let a):
            return "A completed visit cannot be \(a) without the amendment procedure."
        case .visitInProgress(let a):
            return "The visit is in progress and cannot be \(a)."
        case .invalidStatus(let e, let a):
            return "This action requires status \(e), but the appointment is \(a)."
        case .notConfirmed:
            return "The appointment must be confirmed before check-in."
        case .notScheduledToday:
            return "Check-in is only allowed on the scheduled day."
        case .notCheckedIn:
            return "The pet must be checked in before the visit can be completed."
        case .chargesLocked:
            return "Charges are locked after confirmation and cannot be changed."
        case .rescheduleNotAllowed(let t):
            return "\(t) appointments cannot be rescheduled."
        case .dateInPast:
            return "The new date must be in the future."
        case .vaccineNotSelected:
            return "A vaccine must be selected first."
        case .vaccineSpeciesMismatch(let v, let s):
            return "\(v) is not suitable for a \(s)."
        case .vaccineTooSoon(let v, let d):
            return "\(v) was given recently. The next dose is allowed from \(d.short)."
        case .promotionExpired(let c):
            return "Promotion \(c) has expired."
        case .promotionNotEligible(let c, let t):
            return "Promotion \(c) is not available for \(t) appointments."
        case .promotionAlreadyApplied(let c):
            return "Promotion \(c) is already applied."
        case .serviceAlreadyAdded(let n):
            return "Service \"\(n)\" is already added."
        case .requestPending:
            return "There is already a pending change request."
        case .noPendingRequest:
            return "There is no pending request."
        case .reasonRequired:
            return "A written reason is required."
        }
    }
}
