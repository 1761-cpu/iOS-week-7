import SwiftUI

struct ResourcesView: View {
    @EnvironmentObject var manager: LibraryManager
    @State private var searchText = ""
    @State private var filter: ResourceType? = nil

    var displayed: [LibraryResource] { manager.search(searchText, type: filter) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchField(placeholder: "Search title, ID, author, ISBN...", text: $searchText)

                Picker("Type", selection: $filter) {
                    Text("All").tag(ResourceType?.none)
                    ForEach(ResourceType.allCases) { t in
                        Text(t.rawValue).tag(ResourceType?.some(t))
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

                List {
                    if displayed.isEmpty {
                        EmptyHint(systemImage: "magnifyingglass", text: "No resources found.").listRowCard()
                    }
                    ForEach(displayed) { r in
                        NavigationLink {
                            ResourceDetailView(resourceID: r.id)
                        } label: {
                            ResourceCard(resource: r)
                        }
                        .listRowCard()
                    }
                }
                .listStyle(.plain)
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                TopBar(title: "LIBRARY", glassTint: Theme.journal.opacity(0.9), topPadding: 20, bottomPadding: 20) {
                    MemberPicker(color: Theme.journal)
                }
            }
            .screenBackground("libView", fit: true, topOffset: 210)
        }
    }
}

// MARK: - Resource card
struct ResourceCard: View {
    let resource: LibraryResource

    var body: some View {
        let color = Theme.color(for: resource.category)
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                IconBadge(systemName: resource.icon, color: color)
                VStack(alignment: .leading, spacing: 4) {
                    Text(resource.title).font(.headline).lineLimit(2)
                    HStack(spacing: 6) {
                        IDChip(text: resource.id, color: color)
                        Text(resource.typeName).font(.system(size: 12)).foregroundColor(.gray)
                    }
                }
                Spacer()
            }
            HStack {
                StatusPill(text: resource.availabilityText, color: Theme.statusColor(for: resource))
                Spacer()
                if resource.depositAmount > 0 {
                    Text("Deposit \(resource.depositAmount.vnd)").font(.system(size: 11)).foregroundColor(.gray)
                } else if resource.accessFee > 0 {
                    Text("Access fee \(resource.accessFee.vnd)").font(.system(size: 11)).foregroundColor(.gray)
                }
            }
        }
    }
}

#Preview {
    ResourcesView().environmentObject(LibraryManager.preview())
}
