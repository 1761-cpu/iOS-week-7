import SwiftUI

// MARK: - Color & Theme
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
    static let members  = Color(hex: "#DAA520")
    static let billing  = Color(hex: "#CC5500")
    static let basic    = Color(hex: "#2563EB")
    static let premium  = Color(hex: "#B45309")
    static let training = Color(hex: "#059669")
    static let danger   = Color(hex: "#DC2626")
    static let success  = Color(hex: "#16A34A")
    static let warning  = Color(hex: "#D97706")
    static let cardFill = Color(.secondarySystemGroupedBackground)

    static func color(for type: MembershipType) -> Color {
        switch type {
        case .basic: return basic
        case .premium: return premium
        case .personalTraining: return training
        }
    }

    static func color(for status: MembershipStatus) -> Color {
        switch status {
        case .active: return success
        case .suspended: return warning
        case .expired: return danger
        }
    }

    static func color(for role: UserRole) -> Color {
        switch role {
        case .member: return .gray
        case .staff: return warning
        case .manager: return success
        }
    }
}
