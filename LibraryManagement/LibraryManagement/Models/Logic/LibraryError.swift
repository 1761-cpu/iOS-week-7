import Foundation

enum LibraryError: LocalizedError {
    case emptyField(String)
    case invalidYear(Int)
    case invalidCapacity(Int)
    case duplicateResource(String)
    case resourceNotFound(String)
    case memberNotFound(String)
    case notBorrowable(title: String, reason: String)
    case notAvailable(String)
    case duplicateLoan(String)
    case borrowLimitReached(name: String, limit: Int)
    case notBorrowedByMember(String)
    case invalidReturnDate

    var errorDescription: String? {
        switch self {
        case .emptyField(let f):
            return "\(f) cannot be empty."
        case .invalidYear(let y):
            return "Publication year \(y) is invalid."
        case .invalidCapacity(let c):
            return "Simultaneous users must be greater than 0 (got \(c))."
        case .duplicateResource(let id):
            return "Resource ID \(id) already exists."
        case .resourceNotFound(let id):
            return "Resource with ID \(id) not found."
        case .memberNotFound(let id):
            return "Member with ID \(id) not found."
        case .notBorrowable(let title, let reason):
            return "\"\(title)\" cannot be borrowed: \(reason)."
        case .notAvailable(let title):
            return "\"\(title)\" is currently not available (already borrowed / no free seat)."
        case .duplicateLoan(let title):
            return "You are already borrowing \"\(title)\"."
        case .borrowLimitReached(let name, let limit):
            return "\(name) has reached the limit of \(limit) active loans."
        case .notBorrowedByMember(let title):
            return "\"\(title)\" is not borrowed by this member, so it cannot be returned."
        case .invalidReturnDate:
            return "Return date cannot be earlier than the borrow date."
        }
    }
}
