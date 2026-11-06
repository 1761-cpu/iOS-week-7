import Foundation

final class AcademicJournal: LibraryResource {
    private(set) var volume: Int
    private(set) var issue: Int
    let isLendable: Bool           // false = chỉ đọc tại thư viện

    init(id: String, title: String, volume: Int, issue: Int, year: Int, isLendable: Bool) {
        self.volume = volume
        self.issue = issue
        self.isLendable = isLendable
        super.init(id: id, title: title, publicationYear: year)
    }

    override var category: ResourceType { .journal }
    override var typeName: String { "Academic Journal" }
    override var icon: String { "doc.text.fill" }
    override var baseLoanDays: Int { 7 }
    override var depositAmount: Double { 100_000 }
    override var lateFeePerDay: Double { 5_000 }
    override var isBorrowable: Bool { isLendable }
    override var restrictionReason: String { "in-library use only" }
    override var searchableText: String { "vol \(volume) issue \(issue)" }

    override var availabilityText: String {
        isLendable ? super.availabilityText : "In-library only"
    }

    override var detailRows: [InfoItem] {
        super.detailRows + [
            InfoItem(label: "Volume", value: String(volume)),
            InfoItem(label: "Issue", value: String(issue)),
            InfoItem(label: "Lending", value: isLendable ? "Can be borrowed" : "In-library use only")
        ]
    }
}
