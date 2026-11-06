import SwiftUI

// MARK: - Custom Top Bar
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

// MARK: - Role picker
struct RolePicker: View {
    @EnvironmentObject var manager: PayrollManager
    var color: Color = Theme.employees
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
