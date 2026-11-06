import Foundation

final class RoutineConsultation: Appointment {
    let previousVisitDate: Date?      // có giá trị → đây là lượt tái khám (follow-up)

    init(id: String, pet: Pet, scheduledDate: Date, consultationFee: Double,
         previousVisitDate: Date? = nil, notes: String = "", createdDate: Date = Date()) {
        self.previousVisitDate = previousVisitDate
        super.init(id: id, pet: pet, scheduledDate: scheduledDate, baseFee: consultationFee,
                   notes: notes, createdDate: createdDate)
    }

    var isFollowUp: Bool { previousVisitDate != nil }

    /// Tái khám trong vòng 14 ngày kể từ lần khám trước (tính tại thời điểm đặt lịch) → giảm 50% phí khám
    var followUpDiscountApplies: Bool {
        guard let prev = previousVisitDate else { return false }
        let d = Calendar.current.dateComponents([.day], from: prev, to: createdDate).day ?? Int.max
        return (0...14).contains(d)
    }

    override var type: AppointmentType { .routine }
    override var typeName: String { isFollowUp ? "Follow-up Visit" : "Routine Consultation" }
    override var icon: String { isFollowUp ? "arrow.uturn.backward.circle.fill" : "stethoscope" }
    override var feeLabel: String { "Consultation fee" }
    override var priority: Int { 1 }
    override var typeSpecificActions: [String] { isFollowUp ? ["Review previous care"] : [] }

    override func chargeLines() -> [ChargeLine] {
        if followUpDiscountApplies {
            return [ChargeLine(label: "Follow-up consultation (50% of \(baseFee.vnd))", amount: (baseFee * 0.5).rounded())]
        }
        return [ChargeLine(label: "Consultation fee", amount: baseFee)]
    }

    override var typeSpecificRows: [InfoItem] {
        guard let prev = previousVisitDate else { return [] }
        return [InfoItem(label: "Previous visit", value: prev.short),
                InfoItem(label: "Follow-up rate", value: followUpDiscountApplies ? "50% (within 14 days)" : "Standard fee")]
    }
}
