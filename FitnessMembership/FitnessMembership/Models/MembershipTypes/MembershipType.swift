import Foundation

// MARK: - Loại gói, trạng thái, khu vực
enum MembershipType: String, CaseIterable, Identifiable {
    case basic = "Basic"
    case premium = "Premium"
    case personalTraining = "Personal Training"
    var id: String { rawValue }
}

enum MembershipStatus: String, CaseIterable, Identifiable {
    case active = "Active"
    case suspended = "Suspended"
    case expired = "Expired"
    var id: String { rawValue }
}

enum Facility: String, CaseIterable, Identifiable {
    case gymFloor = "Gym Floor"
    case cardio = "Cardio Zone"
    case locker = "Locker Room"
    case pool = "Swimming Pool"
    case sauna = "Sauna"
    case groupStudio = "Group Studio"
    case trainingZone = "Training Zone"
    var id: String { rawValue }

    var icon: String {
        switch self {
        case .gymFloor: return "dumbbell.fill"
        case .cardio: return "figure.run"
        case .locker: return "lock.fill"
        case .pool: return "figure.pool.swim"
        case .sauna: return "flame.fill"
        case .groupStudio: return "person.3.fill"
        case .trainingZone: return "figure.strengthtraining.traditional"
        }
    }
}

// MARK: - Phân quyền
enum Permission {
    case useFacilities, requestChange, editDetails, changeStatus
    case recordPayment, adjustSessions, applyPromotion, manageBilling
}

enum UserRole: String, CaseIterable, Identifiable {
    case member = "Member"
    case staff = "Staff"
    case manager = "Manager"
    var id: String { rawValue }

    func can(_ p: Permission) -> Bool {
        switch self {
        case .member: return p == .useFacilities || p == .requestChange
        case .staff: return p != .requestChange && p != .manageBilling
        case .manager: return p != .requestChange
        }
    }
}

// MARK: - Giờ mở cửa
struct AccessWindow {
    let openHour: Int
    let closeHour: Int
    var text: String { String(format: "%02d:00 – %02d:00", openHour, closeHour) }
    func contains(_ date: Date) -> Bool {
        let h = Calendar.current.component(.hour, from: date)
        return h >= openHour && h < closeHour
    }
}

// MARK: - Khuyến mãi
struct Promotion: Identifiable, Equatable {
    var id: String { code }
    let code: String
    let title: String
    let percentOff: Double
    let eligible: Set<MembershipType>
    let validUntil: Date

    func isValid(on date: Date = Date()) -> Bool { date <= validUntil }
    func isEligible(for type: MembershipType) -> Bool { eligible.contains(type) }

    static var samples: [Promotion] {
        let cal = Calendar.current
        let now = Date()
        func days(_ n: Int) -> Date { cal.date(byAdding: .day, value: n, to: now) ?? now }
        return [
            Promotion(code: "SUMMER10", title: "Summer Deal", percentOff: 10,
                      eligible: [.basic, .premium], validUntil: days(60)),
            Promotion(code: "PTBOOST15", title: "PT Boost", percentOff: 15,
                      eligible: [.personalTraining], validUntil: days(30)),
            Promotion(code: "EARLY20", title: "Early Bird (ended)", percentOff: 20,
                      eligible: [.basic, .premium, .personalTraining], validUntil: days(-10))
        ]
    }
}

// MARK: - Yêu cầu thay đổi từ hội viên
enum RequestKind: String, CaseIterable, Identifiable {
    case freeze = "Freeze membership"
    case unfreeze = "Reactivate membership"
    case trialPremium = "Try Premium (7 days)"
    var id: String { rawValue }
}

struct ChangeRequest: Identifiable {
    let id = UUID()
    let kind: RequestKind
    let date: Date
}

// MARK: - Dữ liệu hiển thị
struct InfoItem: Identifiable {
    let id = UUID()
    let label: String
    let value: String
}

struct ChargeLine: Identifiable {
    let id = UUID()
    let label: String
    let amount: Double
}

struct CheckInRecord: Identifiable {
    let id = UUID()
    let date: Date
    let facility: Facility
}

struct ChargeBreakdown {
    let lines: [ChargeLine]
    let promotion: Promotion?
    let subtotal: Double
    let discount: Double
    let total: Double
    let paid: Double
    let outstanding: Double
}
