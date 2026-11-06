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
    static let appointments = Color(hex: "#0D9488")
    static let charges      = Color(hex: "#7C3AED")
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

// MARK: - Formatting helpers
extension Double {
    var vnd: String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        f.maximumFractionDigits = 0
        return (f.string(from: NSNumber(value: self)) ?? "0") + " ₫"
    }
}

extension Date {
    var short: String { formatted(date: .abbreviated, time: .omitted) }
    var timeText: String { formatted(date: .omitted, time: .shortened) }
    var dateTimeText: String { formatted(date: .abbreviated, time: .shortened) }
}

// MARK: - Alert
extension View {
    func messageAlert(_ title: String, message: Binding<String?>) -> some View {
        alert(title, isPresented: Binding(get: { message.wrappedValue != nil },
                                          set: { if !$0 { message.wrappedValue = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(message.wrappedValue ?? "")
        }
    }
}

// MARK: - Card row modifier
struct ListRowCard: ViewModifier {
    var fill: Color = Theme.cardFill
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 12).fill(fill))
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}
extension View {
    func listRowCard(fill: Color = Theme.cardFill) -> some View { modifier(ListRowCard(fill: fill)) }
}

// MARK: - Small components
struct IDChip: View {
    let text: String
    var color: Color
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundColor(color)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 5))
    }
}

struct StatusPill: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(color.opacity(0.15), in: Capsule())
    }
}

struct IconBadge: View {
    let systemName: String
    let color: Color
    var size: CGFloat = 44
    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundColor(color)
            .frame(width: size, height: size)
            .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).foregroundColor(.gray)
            Spacer()
            Text(value).fontWeight(.medium).multilineTextAlignment(.trailing)
        }
        .font(.system(size: 13))
    }
}

struct EmptyHint: View {
    let systemImage: String
    let text: String
    var color: Color = .gray
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
            Text(text)
        }
        .font(.subheadline)
        .foregroundColor(color)
    }
}

struct SectionTag: View {
    let text: String
    var systemImage: String? = nil
    let color: Color
    init(_ text: String, systemImage: String? = nil, color: Color) {
        self.text = text; self.systemImage = systemImage; self.color = color
    }
    var body: some View {
        HStack(spacing: 6) {
            if let systemImage { Image(systemName: systemImage) }
            Text(text)
        }
        .font(.system(size: 14, weight: .bold))
        .foregroundColor(.white)
        .padding(.horizontal, 12).padding(.vertical, 5)
        .background(color, in: RoundedRectangle(cornerRadius: 12))
        .textCase(nil)
        .padding(.vertical, 4)
    }
}

struct SearchField: View {
    let placeholder: String
    @Binding var text: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundColor(.gray)
            TextField(placeholder, text: $text)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(Theme.cardFill, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

// MARK: - Parse số nhập từ TextField
func parseAmount(_ text: String, field: String) throws -> Double {
    let cleaned = text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
    guard let v = Double(cleaned) else { throw VetError.invalidNumber(field) }
    return v
}

func parseInt(_ text: String, field: String) throws -> Int {
    guard let v = Int(text.trimmingCharacters(in: .whitespaces)) else { throw VetError.invalidNumber(field) }
    return v
}

// MARK: - Role picker (vai trò đang thao tác) - dạng icon trong TopBar
struct RolePicker: View {
    @EnvironmentObject var manager: ClinicManager
    var color: Color = Theme.appointments
    var body: some View {
        Menu {
            Picker("Role", selection: $manager.currentRole) {
                ForEach(UserRole.allCases) { r in Text(r.rawValue).tag(r) }
            }
        } label: {
            Image(systemName: "person.badge.key.fill").font(.title3).foregroundColor(color)
        }
    }
}

struct RoleBanner: View {
    @EnvironmentObject var manager: ClinicManager
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.badge.key.fill").foregroundColor(.gray)
            Text("Acting as").font(.system(size: 13)).foregroundColor(.gray)
            StatusPill(text: manager.currentRole.rawValue, color: Theme.color(for: manager.currentRole))
            Spacer()
            Text("\(manager.appointments.count) appointments").font(.system(size: 13, weight: .semibold))
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Theme.cardFill, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

struct TagChip: View {
    let text: String
    let color: Color
    var systemImage: String? = nil
    var body: some View {
        HStack(spacing: 4) {
            if let systemImage { Image(systemName: systemImage).font(.system(size: 11, weight: .bold)) }
            Text(text).font(.system(size: 12))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(color.opacity(0.12), in: Capsule())
    }
}

// MARK: - FLOW LAYOUT (tự xuống dòng, copy từ bài School Management)
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0, width: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > maxW, x > 0 {
                x = 0
                y += rowH + spacing
                rowH = 0
            }
            x += s.width + spacing
            rowH = max(rowH, s.height)
            width = max(width, x - spacing)
        }
        return CGSize(width: width, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowH + spacing
                rowH = 0
            }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing
            rowH = max(rowH, s.height)
        }
    }
}

struct SummaryBanner: View {
    let icon: String
    let title: String
    let subtitle: String?
    let value: String
    let valueLabel: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 34, height: 34)
                .background(color, in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 14, weight: .bold))
                if let subtitle = subtitle {
                    Text(subtitle).font(.system(size: 11)).foregroundColor(.gray)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 0) {
                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
                Text(valueLabel).font(.system(size: 10)).foregroundColor(.gray)
            }
        }
        .padding(12)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.3), lineWidth: 1))
        .padding(.horizontal, 16)
    }
}

// ==========================================
// MARK: - BACKGROUND (giống bài tham khảo)
// ==========================================
extension View {
    /// Nếu chưa thêm ảnh vào Assets thì tự dùng nền hệ thống, không bị xám.
    func screenBackground(_ imageName: String, opacity: Double = 0.3, fit: Bool = false, topOffset: CGFloat = 0) -> some View {
        self.scrollContentBackground(.hidden)
            .background {
                if UIImage(named: imageName) == nil {
                    Color(.systemGroupedBackground).ignoresSafeArea()
                } else {
                    GeometryReader { geo in
                        ZStack(alignment: .top) {
                            Image(imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.height)
                                .scaleEffect(fit ? 1.15 : 1)
                                .blur(radius: fit ? 30 : 0)
                                .clipped()

                            if fit {
                                Image(imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geo.size.width)
                                    .mask(
                                        LinearGradient(stops: [
                                            .init(color: .clear, location: 0),
                                            .init(color: .black, location: 0.08),
                                            .init(color: .black, location: 0.92),
                                            .init(color: .clear, location: 1)
                                        ], startPoint: .top, endPoint: .bottom)
                                    )
                                    .padding(.top, topOffset)
                            }
                        }
                        .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                        .clipped()
                        .overlay(Color.gray.opacity(opacity))
                    }
                    .ignoresSafeArea()
                }
            }
    }
}

// ==========================================
// MARK: - CUSTOM TOP BAR (copy từ bài tham khảo)
// ==========================================
struct TitleBadge: View {
    let text: String
    let color: Color
    let radius: CGFloat
    let glassTint: Color
    let rim: CGFloat = 6

    var body: some View {
        let inner = RoundedRectangle(cornerRadius: radius)
        let outer = RoundedRectangle(cornerRadius: radius + rim)

        Text(text)
            .font(.system(size: 25, weight: .bold, design: .monospaced))
            .foregroundColor(color)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 14)
            .padding(.vertical, 2)
            .background(Color.white.opacity(0.75), in: inner)
            .padding(rim)
            .glassEffect(.regular.tint(glassTint), in: outer)
    }
}

struct TopBar<Leading: View, Trailing: View>: View {
    let title: String
    var color: Color = .black
    var radius: CGFloat = 12
    var glassTint: Color = .blue.opacity(0.9)
    var topPadding: CGFloat = 0
    var bottomPadding: CGFloat = 12
    var showTrailing = true
    let leading: Leading
    let trailing: Trailing

    init(title: String, color: Color = .black, radius: CGFloat = 12, glassTint: Color = .blue.opacity(0.9), topPadding: CGFloat = 0, bottomPadding: CGFloat = 12, @ViewBuilder leading: () -> Leading, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.color = color
        self.radius = radius
        self.glassTint = glassTint
        self.topPadding = topPadding
        self.bottomPadding = bottomPadding
        self.leading = leading()
        self.trailing = trailing()
    }

    var body: some View {
        HStack {
            leading
            TitleBadge(text: title, color: color, radius: radius, glassTint: glassTint)
            Spacer()
            if showTrailing {
                HStack(spacing: 16) { trailing }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .glassEffect(.regular, in: Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, topPadding)
        .padding(.bottom, bottomPadding)
    }
}

// Chỉ có nút bên phải (Menu/Add), không có nút Back
extension TopBar where Leading == EmptyView {
    init(title: String, color: Color = .black, radius: CGFloat = 12, glassTint: Color = .blue.opacity(0.9), topPadding: CGFloat = 0, bottomPadding: CGFloat = 12, @ViewBuilder trailing: () -> Trailing) {
        self.init(title: title, color: color, radius: radius, glassTint: glassTint, topPadding: topPadding, bottomPadding: bottomPadding, leading: { EmptyView() }, trailing: trailing)
    }
}
