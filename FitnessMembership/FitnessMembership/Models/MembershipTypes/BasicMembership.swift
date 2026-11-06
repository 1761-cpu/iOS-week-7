import Foundation

final class BasicMembership: Membership {
    static let baseFacilities: [Facility] = [.gymFloor, .cardio, .locker]
    static let baseWindow = AccessWindow(openHour: 6, closeHour: 21)

    init(id: String, memberName: String, phone: String, activationDate: Date, monthlyFee: Double) {
        super.init(id: id, memberName: memberName, phone: phone, activationDate: activationDate, unitFee: monthlyFee)
    }

    override var type: MembershipType { .basic }
    override var typeName: String { hasTemporaryUpgrade ? "Basic (+ upgrade)" : "Basic" }
    override var icon: String { "figure.walk" }
    override var supportsTemporaryUpgrade: Bool { true }

    // Đang có upgrade tạm thời → hưởng quyền lợi Premium
    override var facilities: [Facility] {
        hasTemporaryUpgrade ? PremiumMembership.perkFacilities : Self.baseFacilities
    }
    override var accessWindow: AccessWindow {
        hasTemporaryUpgrade ? PremiumMembership.perkWindow : Self.baseWindow
    }

    override func chargeLines() -> [ChargeLine] {
        [ChargeLine(label: "Monthly fee", amount: unitFee)]
    }

    override var benefitRows: [InfoItem] {
        var rows = [InfoItem(label: "Access", value: "General workout areas"),
                    InfoItem(label: "Opening hours", value: accessWindow.text)]
        if let d = temporaryUpgradeUntil, hasTemporaryUpgrade {
            rows.append(InfoItem(label: "Temporary upgrade", value: "Premium access until \(d.short)"))
        }
        return rows
    }
}
