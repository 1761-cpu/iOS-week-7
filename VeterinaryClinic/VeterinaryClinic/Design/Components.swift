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
    var tint: Color? = nil
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(fill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(tint ?? .clear)              
                    )
            )
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}
extension View {
    func listRowCard(fill: Color = Theme.cardFill, tint: Color? = nil) -> some View {
        modifier(ListRowCard(fill: fill, tint: tint))
    }
}

// MARK: - IDChip
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

// MARK: - StatusPill
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

// MARK: - IconBadge
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

// MARK: - InfoRow
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

// MARK: - EmptyHint
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

// MARK: - SectionTag
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

// MARK: - SearchField
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

// MARK: - RoleBanner
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

// MARK: - TagChip
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

// MARK: - FlowLayout
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

// MARK: - SummaryBanner
struct SummaryBanner: View {
    let icon: String
    let title: String
    let subtitle: String?
    let value: String
    let valueLabel: String
    let color: Color

    var customBackgroundColor: Color? = nil

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
        .background(customBackgroundColor ?? color.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.3), lineWidth: 1))
        .padding(.horizontal, 16)
    }
}
