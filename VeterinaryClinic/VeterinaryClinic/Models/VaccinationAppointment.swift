import Foundation

struct Vaccine: Identifiable, Equatable {
    var id: String { code }
    let code: String
    let name: String
    let price: Double
    let boosterIntervalDays: Int
    let species: Set<Species>

    static let catalog: [Vaccine] = [
        Vaccine(code: "RAB", name: "Rabies", price: 250_000, boosterIntervalDays: 365, species: [.dog, .cat]),
        Vaccine(code: "DHPP", name: "DHPP (5-in-1)", price: 300_000, boosterIntervalDays: 365, species: [.dog]),
        Vaccine(code: "FVRCP", name: "FVRCP (3-in-1)", price: 280_000, boosterIntervalDays: 365, species: [.cat]),
        Vaccine(code: "BORD", name: "Bordetella", price: 180_000, boosterIntervalDays: 180, species: [.dog]),
        Vaccine(code: "RHDV", name: "RHDV2", price: 220_000, boosterIntervalDays: 365, species: [.rabbit])
    ]
}

final class VaccinationAppointment: Appointment {
    private(set) var vaccine: Vaccine?

    init(id: String, pet: Pet, scheduledDate: Date, administrationFee: Double,
         vaccine: Vaccine? = nil, notes: String = "") {
        self.vaccine = vaccine
        super.init(id: id, pet: pet, scheduledDate: scheduledDate, baseFee: administrationFee, notes: notes)
    }

    override var type: AppointmentType { .vaccination }
    override var typeName: String { "Vaccination" }
    override var icon: String { "syringe.fill" }
    override var feeLabel: String { "Administration fee" }
    override var priority: Int { 2 }
    override var typeSpecificActions: [String] { chargesLocked ? [] : ["Select vaccine"] }
    override var searchableText: String { (vaccine?.name ?? "").lowercased() }

    override func chargeLines() -> [ChargeLine] {
        var lines = [ChargeLine(label: "Administration fee", amount: baseFee)]
        if let v = vaccine { lines.append(ChargeLine(label: "Vaccine: \(v.name)", amount: v.price)) }
        return lines
    }

    override var typeSpecificRows: [InfoItem] {
        var rows = [InfoItem(label: "Vaccine", value: vaccine?.name ?? "Not selected")]
        if let v = vaccine { rows.append(InfoItem(label: "Booster interval", value: "\(v.boosterIntervalDays) days")) }
        return rows
    }

    /// Kiểm tra loài + lịch sử tiêm của thú cưng
    func validateVaccine(_ v: Vaccine) throws {
        guard v.species.contains(pet.species) else {
            throw VetError.vaccineSpeciesMismatch(vaccine: v.name, species: pet.species.rawValue)
        }
        if let last = pet.lastVaccination(named: v.name),
           let next = Calendar.current.date(byAdding: .day, value: v.boosterIntervalDays, to: last.date),
           scheduledDate < next {
            throw VetError.vaccineTooSoon(vaccine: v.name, nextDate: next)
        }
    }

    func selectVaccine(_ v: Vaccine, by role: UserRole) throws {
        try authorize(role, .editBooking, action: "Select vaccine")
        try ensureNotClosed("modified")
        guard !chargesLocked else { throw VetError.chargesLocked }
        try validateVaccine(v)
        vaccine = v
    }

    override func validateReady() throws {
        guard let v = vaccine else { throw VetError.vaccineNotSelected }
        try validateVaccine(v)
    }

    override func didComplete() {
        if let v = vaccine { pet.recordVaccination(v.name, on: Date()) }
    }

    override func didReopen() {
        if let v = vaccine { pet.removeLastVaccination(named: v.name) }
    }
}
