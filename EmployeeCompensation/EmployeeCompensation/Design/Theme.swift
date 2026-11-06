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
    static let employees = Color(hex: "#2563EB")
    static let payroll   = Color(hex: "#059669")
    static let fullTime  = Color(hex: "#2563EB")
    static let partTime  = Color(hex: "#D97706")
    static let contract  = Color(hex: "#7C3AED")
    static let danger    = Color(hex: "#DC2626")
    static let success   = Color(hex: "#16A34A")
    static let warning   = Color(hex: "#D97706")
    static let cardFill  = Color(.secondarySystemGroupedBackground)

    static func color(for type: EmploymentType) -> Color {
        switch type {
        case .fullTime: return fullTime
        case .partTime: return partTime
        case .contract: return contract
        }
    }

    static func color(for role: UserRole) -> Color {
        switch role {
        case .hrStaff: return partTime
        case .payrollAdmin: return success
        case .viewer: return .gray
        }
    }
}
