import SwiftUI

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
}

// MARK: - ID Chip
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

// MARK: - Status Pill
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

// MARK: - Icon Badge
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

// MARK: - Info Row
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

// MARK: - Empty Hint
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

// MARK: - Section Tag
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

// MARK: - Search Field
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
