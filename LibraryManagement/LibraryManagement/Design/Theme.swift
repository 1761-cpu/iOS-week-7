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
    static let book    = Color(hex: "#8B5E34")
    static let journal = Color(hex: "#474700")
    static let digital = Color(hex: "#702963")
    static let loans   = Color(hex: "#FFBF00")
    static let danger  = Color(hex: "#DC2626")
    static let success = Color(hex: "#16A34A")
    static let warning = Color(hex: "#D97706")
    static let cardFill = Color(.secondarySystemGroupedBackground)

    static func color(for type: ResourceType) -> Color {
        switch type {
        case .book: return book
        case .journal: return journal
        case .digital: return digital
        }
    }

    static func statusColor(for r: LibraryResource) -> Color {
        if !r.isBorrowable { return .gray }
        return r.isAvailable ? success : danger
    }
}
