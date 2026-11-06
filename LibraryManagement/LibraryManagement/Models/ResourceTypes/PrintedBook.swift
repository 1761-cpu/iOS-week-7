import Foundation

final class PrintedBook: LibraryResource {
    private(set) var author: String
    private(set) var isbn: String
    let isShortLoan: Bool          // sách giới hạn thời gian mượn ngắn

    init(id: String, title: String, author: String, isbn: String, year: Int, isShortLoan: Bool = false) {
        self.author = author
        self.isbn = isbn
        self.isShortLoan = isShortLoan
        super.init(id: id, title: title, publicationYear: year)
    }

    override var category: ResourceType { .book }
    override var typeName: String { isShortLoan ? "Printed Book (short loan)" : "Printed Book" }
    override var icon: String { "book.fill" }
    override var baseLoanDays: Int { isShortLoan ? 7 : 28 }
    override var depositAmount: Double { isShortLoan ? 50_000 : 0 }
    override var lateFeePerDay: Double { isShortLoan ? 5_000 : 2_000 }
    override var searchableText: String { (author + " " + isbn).lowercased() }

    override var detailRows: [InfoItem] {
        super.detailRows + [
            InfoItem(label: "Author", value: author),
            InfoItem(label: "ISBN", value: isbn)
        ]
    }
}
