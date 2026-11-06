import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = (int >> 16) & 0xFF, g = (int >> 8) & 0xFF, b = int & 0xFF
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }
}

enum Theme {
    static let appointments = Color(hex: "#0D9488")
    static let charges      = Color(hex: "#DAA520")
    static let routine      = Color(hex: "#2563EB")
    static let vaccination  = Color(hex: "#D97706")
    static let emergency    = Color(hex: "#DC2626")
    static let danger       = Color(hex: "#DC2626")
    static let success      = Color(hex: "#16A34A")
    static let warning      = Color(hex: "#D97706")
    static let cardFill     = Color(.secondarySystemGroupedBackground)

    static func color(for type: AppointmentType) -> Color {
        switch type {
        case .routine: return routine
        case .vaccination: return vaccination
        case .emergency: return emergency
        }
    }

    static func color(for status: AppointmentStatus) -> Color {
        switch status {
        case .booked: return .gray
        case .confirmed: return routine
        case .checkedIn: return warning
        case .completed: return success
        case .cancelled: return danger
        }
    }

    static func color(for role: UserRole) -> Color {
        switch role {
        case .owner: return .gray
        case .receptionist: return warning
        case .vet: return appointments
        case .manager: return success
        }
    }
}
