import Foundation

// MARK: - Loại lịch hẹn, trạng thái, loài vật
enum AppointmentType: String, CaseIterable, Identifiable {
    case routine = "Routine"
    case vaccination = "Vaccination"
    case emergency = "Emergency"
    var id: String { rawValue }
}

enum AppointmentStatus: String, CaseIterable, Identifiable {
    case booked = "Booked"
    case confirmed = "Confirmed"
    case checkedIn = "Checked-in"
    case completed = "Completed"
    case cancelled = "Cancelled"
    var id: String { rawValue }
}

enum Species: String, CaseIterable, Identifiable {
    case dog = "Dog"
    case cat = "Cat"
    case rabbit = "Rabbit"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .dog: return "dog.fill"
        case .cat: return "cat.fill"
        case .rabbit: return "hare.fill"
        }
    }
}

// MARK: - Phân quyền
enum Permission { case requestChange, editBooking, addService, completeVisit, changeFees, amendCompleted }

enum UserRole: String, CaseIterable, Identifiable {
    case owner = "Pet Owner"
    case receptionist = "Receptionist"
    case vet = "Veterinarian"
    case manager = "Manager"
    var id: String { rawValue }

    func can(_ p: Permission) -> Bool {
        switch self {
        case .owner: return p == .requestChange
        case .receptionist: return p == .editBooking || p == .addService
        case .vet: return p == .addService || p == .completeVisit
        case .manager: return p != .requestChange
        }
    }
}

// MARK: - Chủ nuôi & thú cưng
final class Owner: Identifiable {
    let id: String
    private(set) var name: String
    private(set) var phone: String

    init(id: String, name: String, phone: String) {
        self.id = id
        self.name = name
        self.phone = phone
    }
}

struct VaccinationRecord: Identifiable {
    let id = UUID()
    let vaccineName: String
    let date: Date
}

final class Pet: Identifiable {
    let id: String
    let species: Species
    let owner: Owner
    private(set) var name: String
    private(set) var ageYears: Int
    private(set) var vaccinationHistory: [VaccinationRecord] = []   // chỉ đổi khi hoàn tất tiêm / mở lại

    init(id: String, name: String, species: Species, ageYears: Int, owner: Owner) {
        self.id = id
        self.name = name
        self.species = species
        self.ageYears = ageYears
        self.owner = owner
    }

    func lastVaccination(named vaccine: String) -> VaccinationRecord? {
        vaccinationHistory.filter { $0.vaccineName == vaccine }.max { $0.date < $1.date }
    }

    func recordVaccination(_ vaccine: String, on date: Date) {
        vaccinationHistory.append(VaccinationRecord(vaccineName: vaccine, date: date))
    }

    func removeLastVaccination(named vaccine: String) {
        if let i = vaccinationHistory.lastIndex(where: { $0.vaccineName == vaccine }) {
            vaccinationHistory.remove(at: i)
        }
    }
}

// MARK: - Dịch vụ thêm & khuyến mãi
struct ServiceItem: Identifiable, Equatable {
    var id: String { code }
    let code: String
    let name: String
    let price: Double

    static let catalog: [ServiceItem] = [
        ServiceItem(code: "NAIL", name: "Nail trimming", price: 80_000),
        ServiceItem(code: "MICRO", name: "Microchip implant", price: 200_000),
        ServiceItem(code: "DENTAL", name: "Dental check", price: 150_000),
        ServiceItem(code: "DEWORM", name: "Deworming", price: 100_000)
    ]
}

enum DiscountScope { case total, servicesOnly }

struct Promotion: Identifiable, Equatable {
    var id: String { code }
    let code: String
    let title: String
    let percentOff: Double
    let scope: DiscountScope
    let eligible: Set<AppointmentType>
    let validUntil: Date

    func isValid(on date: Date = Date()) -> Bool { date <= validUntil }
    func isEligible(for type: AppointmentType) -> Bool { eligible.contains(type) }

    static var samples: [Promotion] {
        let cal = Calendar.current
        let now = Date()
        func days(_ n: Int) -> Date { cal.date(byAdding: .day, value: n, to: now) ?? now }
        return [
            Promotion(code: "WELLNESS10", title: "Wellness Month", percentOff: 10, scope: .total,
                      eligible: [.routine, .vaccination], validUntil: days(45)),
            Promotion(code: "BUNDLE20", title: "Service Bundle (extras only)", percentOff: 20, scope: .servicesOnly,
                      eligible: [.routine, .vaccination], validUntil: days(30)),
            Promotion(code: "EXPIRED15", title: "Spring Sale (ended)", percentOff: 15, scope: .total,
                      eligible: [.routine, .vaccination, .emergency], validUntil: days(-5))
        ]
    }
}

// MARK: - Yêu cầu thay đổi từ chủ nuôi
enum ChangeRequestKind {
    case cancel
    case reschedule(Date)

    var title: String {
        switch self {
        case .cancel: return "Cancel appointment"
        case .reschedule(let d): return "Reschedule to \(d.dateTimeText)"
        }
    }
}

struct ChangeRequest: Identifiable {
    let id = UUID()
    let kind: ChangeRequestKind
    let date: Date
}

struct Amendment: Identifiable {
    let id = UUID()
    let reason: String
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

struct ChargeBreakdown {
    let lines: [ChargeLine]
    let promotion: Promotion?
    let subtotal: Double
    let discount: Double
    let total: Double
}
