import Foundation

enum UrgencyLevel: String, CaseIterable, Identifiable {
    case urgent = "Urgent"
    case critical = "Critical"
    var id: String { rawValue }
    var surcharge: Double { self == .critical ? 300_000 : 150_000 }
}

final class EmergencyAppointment: Appointment {
    let urgency: UrgencyLevel
    let symptoms: String

    init(id: String, pet: Pet, scheduledDate: Date, emergencyFee: Double,
         urgency: UrgencyLevel, symptoms: String) {
        self.urgency = urgency
        self.symptoms = symptoms
        // Cấp cứu được xác nhận ngay (ưu tiên)
        super.init(id: id, pet: pet, scheduledDate: scheduledDate, baseFee: emergencyFee,
                   notes: symptoms, initialStatus: .confirmed)
    }

    /// Ngoài giờ hành chính (08:00 – 18:00) → phụ phí
    var isAfterHours: Bool {
        let h = Calendar.current.component(.hour, from: scheduledDate)
        return h < 8 || h >= 18
    }

    override var type: AppointmentType { .emergency }
    override var typeName: String { "Emergency (\(urgency.rawValue))" }
    override var icon: String { "cross.case.fill" }
    override var feeLabel: String { "Emergency fee" }
    override var priority: Int { 0 }
    override var allowedCheckInStatuses: Set<AppointmentStatus> { [.booked, .confirmed] }
    override var requiresSameDayCheckIn: Bool { false }        // tiếp nhận ngay
    override var allowsReschedule: Bool { false }
    override var typeSpecificActions: [String] { ["Immediate triage"] }
    override var searchableText: String { symptoms.lowercased() }

    override func chargeLines() -> [ChargeLine] {
        var lines = [ChargeLine(label: "Emergency fee", amount: baseFee),
                     ChargeLine(label: "Urgency surcharge (\(urgency.rawValue))", amount: urgency.surcharge)]
        if isAfterHours {
            lines.append(ChargeLine(label: "After-hours surcharge (50% of fee)", amount: (baseFee * 0.5).rounded()))
        }
        return lines
    }

    override var typeSpecificRows: [InfoItem] {
        [InfoItem(label: "Priority", value: "Highest — immediate attention"),
         InfoItem(label: "Urgency", value: urgency.rawValue),
         InfoItem(label: "Symptoms", value: symptoms),
         InfoItem(label: "After hours", value: isAfterHours ? "Yes (surcharge applies)" : "No")]
    }
}
