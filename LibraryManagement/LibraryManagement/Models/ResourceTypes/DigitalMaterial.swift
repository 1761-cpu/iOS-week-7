import Foundation

final class DigitalMaterial: LibraryResource {
    private(set) var platform: String
    private(set) var licenseExpiry: Date
    private(set) var maxUsers: Int

    init(id: String, title: String, platform: String, year: Int, licenseExpiry: Date, maxUsers: Int) {
        self.platform = platform
        self.licenseExpiry = licenseExpiry
        self.maxUsers = maxUsers
        super.init(id: id, title: title, publicationYear: year)
    }

    var isLicenseValid: Bool { licenseExpiry >= Calendar.current.startOfDay(for: Date()) }

    override var category: ResourceType { .digital }
    override var typeName: String { "Digital Material" }
    override var icon: String { "laptopcomputer" }
    override var capacity: Int { maxUsers }                // nhiều người dùng đồng thời
    override var baseLoanDays: Int { 3 }                   // thời hạn phiên truy cập
    override var accessFee: Double { 5_000 }               // phí truy cập, không có tiền cọc
    override var lateFeePerDay: Double { 0 }               // hết hạn tự động thu hồi quyền
    override var isBorrowable: Bool { isLicenseValid }
    override var restrictionReason: String { "the license has expired" }
    override var actionVerb: String { "Access" }
    override var returnVerb: String { "Release access" }
    override var searchableText: String { platform.lowercased() }

    override var availabilityText: String {
        isLicenseValid ? super.availabilityText : "License expired"
    }

    override var detailRows: [InfoItem] {
        super.detailRows + [
            InfoItem(label: "Platform", value: platform),
            InfoItem(label: "License expires", value: licenseExpiry.short),
            InfoItem(label: "Simultaneous users", value: "\(loans.count)/\(maxUsers)")
        ]
    }
}
