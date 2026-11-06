import Foundation
import Combine

final class LibraryManager: ObservableObject {
    // MARK: - Data (chỉ đọc từ bên ngoài)
    @Published private(set) var resources: [LibraryResource] = []
    @Published private(set) var members: [Member] = []
    @Published var currentMemberID: String = ""

    init(sample: Bool = false) {
        if sample { loadSampleData() }
    }

    // MARK: - Lookup
    func resource(withID id: String) -> LibraryResource? { resources.first { $0.id == id } }
    func member(withID id: String) -> Member? { members.first { $0.id == id } }
    var currentMember: Member? { member(withID: currentMemberID) }

    func activeLoanCount(ofMember id: String) -> Int {
        resources.reduce(0) { $0 + $1.loans.filter { $0.memberID == id }.count }
    }

    func loans(ofMember id: String) -> [(resource: LibraryResource, loan: Loan)] {
        resources.compactMap { r in
            guard let l = r.loans.first(where: { $0.memberID == id }) else { return nil }
            return (r, l)
        }
        .sorted { $0.loan.dueDate < $1.loan.dueDate }
    }

    func search(_ keyword: String, type: ResourceType?) -> [LibraryResource] {
        let k = keyword.trimmingCharacters(in: .whitespaces).lowercased()
        return resources.filter { r in
            (type == nil || r.category == type)
            && (k.isEmpty
                || r.id.lowercased().contains(k)
                || r.title.lowercased().contains(k)
                || r.searchableText.contains(k))
        }
    }

    // MARK: - Add data (có validation)
    func addResource(_ resource: LibraryResource) throws {
        let cleanID = resource.id.trimmingCharacters(in: .whitespaces)
        guard !cleanID.isEmpty else { throw LibraryError.emptyField("Resource ID") }
        guard !resource.title.trimmingCharacters(in: .whitespaces).isEmpty else { throw LibraryError.emptyField("Title") }
        let year = Calendar.current.component(.year, from: Date())
        guard (1450...(year + 1)).contains(resource.publicationYear) else {
            throw LibraryError.invalidYear(resource.publicationYear)
        }
        if let d = resource as? DigitalMaterial, d.maxUsers <= 0 { throw LibraryError.invalidCapacity(d.maxUsers) }
        guard self.resource(withID: cleanID) == nil else { throw LibraryError.duplicateResource(cleanID) }
        resources.append(resource)
    }

    func addMember(_ member: Member) {
        guard self.member(withID: member.id) == nil else { return }
        members.append(member)
    }

    // MARK: - Borrow / Return
    @discardableResult
    func borrow(resourceID: String, memberID: String, on date: Date = Date()) throws -> Loan {
        guard let member = member(withID: memberID) else { throw LibraryError.memberNotFound(memberID) }
        guard let res = resource(withID: resourceID) else { throw LibraryError.resourceNotFound(resourceID) }
        guard activeLoanCount(ofMember: memberID) < member.role.borrowLimit else {
            throw LibraryError.borrowLimitReached(name: member.name, limit: member.role.borrowLimit)
        }
        let loan = try res.borrow(by: member, on: date)
        objectWillChange.send()
        return loan
    }

    @discardableResult
    func giveBack(resourceID: String, memberID: String, on date: Date = Date()) throws -> ReturnReceipt {
        guard member(withID: memberID) != nil else { throw LibraryError.memberNotFound(memberID) }
        guard let res = resource(withID: resourceID) else { throw LibraryError.resourceNotFound(resourceID) }
        let receipt = try res.giveBack(memberID: memberID, on: date)
        objectWillChange.send()
        return receipt
    }

    // MARK: - Sample data
    private func loadSampleData() {
        let cal = Calendar.current
        let now = Date()
        func days(_ n: Int) -> Date { cal.date(byAdding: .day, value: n, to: now) ?? now }

        members = [
            Member(id: "M001", name: "Nguyễn Ánh", role: .student),
            Member(id: "M002", name: "Phạm Bảo", role: .student),
            Member(id: "L001", name: "TS. Diệp Dương", role: .lecturer)
        ]
        currentMemberID = "M001"

        let items: [LibraryResource] = [
            PrintedBook(id: "B001", title: "Clean Code", author: "Robert C. Martin", isbn: "9780132350884", year: 2008),
            PrintedBook(id: "B002", title: "Introduction to Algorithms", author: "Cormen, Leiserson, Rivest, Stein", isbn: "9780262033848", year: 2009, isShortLoan: true),
            PrintedBook(id: "B003", title: "Design Patterns", author: "Gamma, Helm, Johnson, Vlissides", isbn: "9780201633610", year: 1994),
            AcademicJournal(id: "J001", title: "Journal of Software Engineering", volume: 12, issue: 3, year: 2024, isLendable: true),
            AcademicJournal(id: "J002", title: "Computing Research Letters", volume: 8, issue: 1, year: 2025, isLendable: false),
            DigitalMaterial(id: "D001", title: "SwiftUI Interactive Course", platform: "UniLearn Online", year: 2025, licenseExpiry: days(180), maxUsers: 3),
            DigitalMaterial(id: "D002", title: "Python for Data Science (e-book)", platform: "UniLearn Online", year: 2023, licenseExpiry: days(90), maxUsers: 1),
            DigitalMaterial(id: "D003", title: "Legacy Lecture Archive", platform: "UniLearn Online", year: 2019, licenseExpiry: days(-30), maxUsers: 5)
        ]
        for r in items { try? addResource(r) }

        // M002 mượn quá hạn B002 (mượn 25 ngày trước, hạn 7 ngày) → demo phí phạt
        _ = try? borrow(resourceID: "B002", memberID: "M002", on: days(-25))
        // M002 đang mượn B001 → M001 mượn sẽ bị từ chối (đã có người mượn)
        _ = try? borrow(resourceID: "B001", memberID: "M002")
        // Vài lượt truy cập tài liệu số
        _ = try? borrow(resourceID: "D001", memberID: "M002")
        _ = try? borrow(resourceID: "D001", memberID: "L001")
    }
}

extension LibraryManager {
    static func preview() -> LibraryManager { LibraryManager(sample: true) }
}
