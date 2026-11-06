import SwiftUI

// MARK: - Formatting helpers
extension Double {
    /// Định dạng số theo kiểu tiền Việt Nam (phân tách hàng nghìn bằng dấu phẩy, kèm hậu tố "₫").
    var vnd: String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        f.maximumFractionDigits = 0
        return (f.string(from: NSNumber(value: self)) ?? "0") + " ₫"
    }
}

extension Date {
    /// Chuỗi ngày dạng ngắn gọn (abbreviated date, không kèm giờ).
    var short: String { formatted(date: .abbreviated, time: .omitted) }
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
/// Parse chuỗi người dùng nhập thành `Double`.
/// - Chấp nhận dấu phẩy `,` hoặc dấu chấm `.` làm phân tách thập phân.
/// - Ném `PayrollError.invalidNumber(field)` nếu chuỗi không phải số hợp lệ.
func parseAmount(_ text: String, field: String) throws -> Double {
    let cleaned = text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
    guard let v = Double(cleaned) else { throw PayrollError.invalidNumber(field) }
    return v
}

// MARK: - RoleBanner
struct RoleBanner: View {
    @EnvironmentObject var manager: PayrollManager
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.badge.key.fill").foregroundColor(.gray)
            Text("Acting as").font(.system(size: 13)).foregroundColor(.gray)
            StatusPill(text: manager.currentRole.rawValue, color: Theme.color(for: manager.currentRole))
            Spacer()
            Text(manager.selectedMonth.title).font(.system(size: 13, weight: .semibold))
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Theme.cardFill, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

// MARK: - MonthSwitcher
struct MonthSwitcher: View {
    @EnvironmentObject var manager: PayrollManager
    var body: some View {
        HStack {
            Button { manager.selectedMonth = manager.selectedMonth.previous } label: {
                Image(systemName: "chevron.left.circle.fill").font(.title3)
            }
            .buttonStyle(.borderless)
            Spacer()
            Text(manager.selectedMonth.title).font(.headline)
            Spacer()
            Button { manager.selectedMonth = manager.selectedMonth.next } label: {
                Image(systemName: "chevron.right.circle.fill").font(.title3)
            }
            .buttonStyle(.borderless)
        }
        .foregroundColor(Theme.payroll)
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
                    Text(subtitle).font(.system(size: 11)).foregroundColor(.black)
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
