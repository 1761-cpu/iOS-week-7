import Foundation
import Combine

final class MembershipManager: ObservableObject {
    // MARK: - Data
    @Published private(set) var memberships: [Membership] = []
    @Published var currentRole: UserRole = .staff
    let promotions = Promotion.samples

    init(sample: Bool = false) {
        if sample { loadSampleData() }
    }

    // MARK: - Lookup & search
    func membership(withID id: String) -> Membership? { memberships.first { $0.id == id } }

    func search(_ keyword: String, type: MembershipType?) -> [Membership] {
        let k = keyword.trimmingCharacters(in: .whitespaces).lowercased()
        return memberships.filter { m in
            (type == nil || m.type == type)
            && (k.isEmpty
                || m.id.lowercased().contains(k)
                || m.memberName.lowercased().contains(k)
                || m.searchableText.contains(k))
        }
    }

    // MARK: - Add
    func addMembership(_ m: Membership) throws {
        let cleanID = m.id.trimmingCharacters(in: .whitespaces)
        guard !cleanID.isEmpty else { throw MembershipError.emptyField("Membership ID") }
        guard !m.memberName.trimmingCharacters(in: .whitespaces).isEmpty else { throw MembershipError.emptyField("Member name") }
        guard membership(withID: cleanID) == nil else { throw MembershipError.duplicateMembership(cleanID) }
        memberships.append(m)
    }

    // MARK: - Chạy 1 thao tác và làm mới UI
    func attempt(_ action: () throws -> String) -> String {
        defer { objectWillChange.send() }
        do { return try action() } catch { return "Rejected: " + error.localizedDescription }
    }

    // MARK: - Tổng hợp (đa hình: breakdown gọi chargeLines của từng loại)
    var totalEstimated: Double { memberships.reduce(0) { $0 + $1.estimatedCharges } }
    var totalPaid: Double { memberships.reduce(0) { $0 + $1.amountPaid } }
    var totalOutstanding: Double { memberships.reduce(0) { $0 + $1.outstanding } }

    // MARK: - Sample data
    private func loadSampleData() {
        let mgr = UserRole.manager
        func daysAgo(_ n: Int) -> Date { Calendar.current.date(byAdding: .day, value: -n, to: Date()) ?? Date() }
        func promo(_ code: String) -> Promotion? { promotions.first { $0.code == code } }

        let list: [Membership] = [
            BasicMembership(id: "M001", memberName: "Nguyễn Ánh", phone: "0901 111 111", activationDate: daysAgo(180), monthlyFee: 300_000),
            PremiumMembership(id: "M002", memberName: "Phạm Bảo", phone: "0902 222 222", activationDate: daysAgo(120), monthlyFee: 700_000),
            PersonalTrainingMembership(id: "M003", memberName: "Trần Đông", phone: "0903 333 333", activationDate: daysAgo(60),
                                       pricePerSession: 400_000, packageSessions: 8, coachName: "Coach Minh"),
            BasicMembership(id: "M004", memberName: "Hạ Cẩm", phone: "0904 444 444", activationDate: daysAgo(90), monthlyFee: 300_000),
            PremiumMembership(id: "M005", memberName: "Cao Khánh", phone: "0905 555 555", activationDate: daysAgo(300), monthlyFee: 700_000),
            BasicMembership(id: "M006", memberName: "Lê Ninh", phone: "0906 666 666", activationDate: daysAgo(30), monthlyFee: 300_000)
        ]
        for m in list { try? addMembership(m) }

        // M001: đã thanh toán đủ
        try? membership(withID: "M001")?.recordPayment(300_000, by: mgr)

        // M002: khuyến mãi 10%, đã dùng 7/8 lớp nhóm, còn nợ
        if let m = membership(withID: "M002") as? PremiumMembership {
            if let p = promo("SUMMER10") { try? m.applyPromotion(p, by: mgr) }
            for _ in 0..<7 { try? m.bookGroupClass(named: "Yoga", by: mgr) }
            try? m.recordPayment(300_000, by: mgr)
        }

        // M003: PT, đã tập 7/8 buổi → còn 1 buổi
        if let m = membership(withID: "M003") as? PersonalTrainingMembership {
            for _ in 0..<7 { try? m.attendSession(by: mgr) }
            try? m.recordPayment(1_000_000, by: mgr)
        }

        // M004: bị tạm ngưng → không check-in được
        try? membership(withID: "M004")?.recordPayment(300_000, by: mgr)
        try? membership(withID: "M004")?.setStatus(.suspended, by: mgr)

        // M005: hết hạn, còn nợ → không thể kích hoạt lại
        try? membership(withID: "M005")?.recordPayment(200_000, by: mgr)
        try? membership(withID: "M005")?.setStatus(.expired, by: mgr)

        // M006: Basic có nâng cấp tạm thời 7 ngày
        try? membership(withID: "M006")?.grantTemporaryUpgrade(days: 7, by: mgr)
        try? membership(withID: "M006")?.recordPayment(300_000, by: mgr)

        currentRole = .staff
    }
}

extension MembershipManager {
    static func preview() -> MembershipManager { MembershipManager(sample: true) }
}
