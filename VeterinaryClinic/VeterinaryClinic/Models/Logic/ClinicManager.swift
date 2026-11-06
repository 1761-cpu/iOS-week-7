import Foundation
import Combine

final class ClinicManager: ObservableObject {
    // MARK: - Data
    @Published private(set) var appointments: [Appointment] = []
    @Published var currentRole: UserRole = .receptionist
    let promotions = Promotion.samples

    init(sample: Bool = false) {
        if sample { loadSampleData() }
    }

    // MARK: - Lookup & search (ưu tiên cấp cứu trước, rồi theo thời gian)
    func appointment(withID id: String) -> Appointment? { appointments.first { $0.id == id } }

    func search(_ keyword: String, type: AppointmentType?) -> [Appointment] {
        let k = keyword.trimmingCharacters(in: .whitespaces).lowercased()
        return appointments.filter { a in
            (type == nil || a.type == type)
            && (k.isEmpty
                || a.id.lowercased().contains(k)
                || a.pet.name.lowercased().contains(k)
                || a.owner.name.lowercased().contains(k)
                || a.searchableText.contains(k))
        }
        .sorted { ($0.priority, $0.scheduledDate) < ($1.priority, $1.scheduledDate) }
    }

    // MARK: - Add
    func addAppointment(_ a: Appointment) throws {
        let cleanID = a.id.trimmingCharacters(in: .whitespaces)
        guard !cleanID.isEmpty else { throw VetError.emptyField("Appointment ID") }
        guard appointment(withID: cleanID) == nil else { throw VetError.duplicateAppointment(cleanID) }
        appointments.append(a)
    }

    // MARK: - Chạy 1 thao tác và làm mới UI
    func attempt(_ action: () throws -> String) -> String {
        defer { objectWillChange.send() }
        do { return try action() } catch { return "Rejected: " + error.localizedDescription }
    }

    // MARK: - Tổng hợp (đa hình: breakdown gọi chargeLines của từng loại)
    var totalEstimated: Double { appointments.reduce(0) { $0 + $1.estimatedCharges } }
    var lockedCount: Int { appointments.filter { $0.chargesLocked }.count }

    // MARK: - Sample data
    private func loadSampleData() {
        let mgr = UserRole.manager
        let cal = Calendar.current
        let now = Date()
        func day(_ offset: Int, hour: Int, minute: Int = 0) -> Date {
            let base = cal.date(byAdding: .day, value: offset, to: now) ?? now
            return cal.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base
        }
        func daysAgo(_ n: Int) -> Date { cal.date(byAdding: .day, value: -n, to: now) ?? now }
        func promo(_ code: String) -> Promotion? { promotions.first { $0.code == code } }
        func service(_ code: String) -> ServiceItem? { ServiceItem.catalog.first { $0.code == code } }
        func vaccine(_ code: String) -> Vaccine? { Vaccine.catalog.first { $0.code == code } }

        let o1 = Owner(id: "O001", name: "Nguyễn Ánh", phone: "0901 111 111")
        let o2 = Owner(id: "O002", name: "Phạm Bảo", phone: "0902 222 222")
        let o3 = Owner(id: "O003", name: "Trần Đông", phone: "0903 333 333")
        let milo = Pet(id: "P001", name: "Milo", species: .dog, ageYears: 3, owner: o1)
        let luna = Pet(id: "P002", name: "Luna", species: .cat, ageYears: 2, owner: o1)
        let bun = Pet(id: "P003", name: "Bun", species: .rabbit, ageYears: 1, owner: o2)
        let rex = Pet(id: "P004", name: "Rex", species: .dog, ageYears: 5, owner: o3)
        rex.recordVaccination("Rabies", on: daysAgo(100))        // tiêm dại cách đây 100 ngày

        let a1 = RoutineConsultation(id: "A001", pet: milo, scheduledDate: day(0, hour: 10), consultationFee: 200_000, notes: "Annual check-up")
        let a2 = RoutineConsultation(id: "A002", pet: luna, scheduledDate: day(0, hour: 14), consultationFee: 200_000,
                                     previousVisitDate: daysAgo(7), notes: "Follow-up on skin rash")
        let a3 = VaccinationAppointment(id: "A003", pet: rex, scheduledDate: day(0, hour: 11), administrationFee: 50_000)
        let a4 = EmergencyAppointment(id: "A004", pet: bun, scheduledDate: day(0, hour: 22, minute: 30), emergencyFee: 500_000,
                                      urgency: .critical, symptoms: "Not eating, bloated abdomen")
        let a5 = RoutineConsultation(id: "A005", pet: milo, scheduledDate: day(1, hour: 9), consultationFee: 200_000)
        let a6 = VaccinationAppointment(id: "A006", pet: rex, scheduledDate: day(2, hour: 15), administrationFee: 50_000)
        let a7 = RoutineConsultation(id: "A007", pet: rex, scheduledDate: day(-1, hour: 9), consultationFee: 200_000, notes: "Limping on left leg")
        let a8 = RoutineConsultation(id: "A008", pet: luna, scheduledDate: day(3, hour: 10), consultationFee: 200_000)

        for a in [a1, a2, a3, a4, a5, a6, a7, a8] as [Appointment] { try? addAppointment(a) }

        // A001: bundle + dịch vụ thêm, rồi xác nhận
        if let p = promo("BUNDLE20") { try? a1.applyPromotion(p, by: mgr) }
        if let s = service("NAIL") { try? a1.addService(s, by: mgr) }
        if let s = service("DENTAL") { try? a1.addService(s, by: mgr) }
        try? a1.confirm(by: mgr)

        // A002: để trạng thái Booked (chưa xác nhận)

        // A003: chọn vắc-xin DHPP, giảm 10%, xác nhận
        if let v = vaccine("DHPP") { try? a3.selectVaccine(v, by: mgr) }
        if let p = promo("WELLNESS10") { try? a3.applyPromotion(p, by: mgr) }
        try? a3.confirm(by: mgr)

        // A005: xác nhận (ngày mai → chưa check-in được)
        try? a5.confirm(by: mgr)

        // A006: vắc-xin của Rex còn để Booked, chưa chọn vắc-xin (thử chọn Rabies → quá sớm)

        // A008: bị hủy → không thể check-in
        try? a8.cancel(by: mgr)

        // A007: đã khám xong hôm qua → không thể đổi lịch
        try? a7.confirm(by: mgr)
        try? a7.checkIn(at: a7.scheduledDate, by: mgr)
        try? a7.complete(by: mgr)

        currentRole = .receptionist
    }
}

extension ClinicManager {
    static func preview() -> ClinicManager { ClinicManager(sample: true) }
}
