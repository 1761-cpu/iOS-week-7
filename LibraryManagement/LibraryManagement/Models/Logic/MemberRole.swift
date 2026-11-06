import Foundation

// MARK: - Vai trò người dùng (ảnh hưởng chính sách mượn)
enum MemberRole: String, CaseIterable {
    case student = "Student"
    case lecturer = "Lecturer"

    var borrowLimit: Int { self == .student ? 3 : 5 }
    var loanMultiplier: Double { self == .student ? 1.0 : 2.0 }   // giảng viên được mượn lâu gấp đôi
}

final class Member: Identifiable {
    let id: String
    private(set) var name: String
    let role: MemberRole

    init(id: String, name: String, role: MemberRole) {
        self.id = id
        self.name = name
        self.role = role
    }

    func setName(_ newName: String) {
        let clean = newName.trimmingCharacters(in: .whitespaces)
        if !clean.isEmpty { name = clean }
    }
}
