import SwiftUI

struct MembersView: View {
    @EnvironmentObject var manager: MembershipManager
    @State private var searchText = ""
    @State private var filter: MembershipType? = nil

    var displayed: [Membership] { manager.search(searchText, type: filter) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchField(placeholder: "Search name, ID, coach...", text: $searchText)

                Picker("Plan", selection: $filter) {
                    Text("All").tag(MembershipType?.none)
                    Text("Basic").tag(MembershipType?.some(.basic))
                    Text("Premium").tag(MembershipType?.some(.premium))
                    Text("PT").tag(MembershipType?.some(.personalTraining))
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

                RoleBanner()

                List {
                    if displayed.isEmpty {
                        EmptyHint(systemImage: "magnifyingglass", text: "No memberships found.").listRowCard()
                    }
                    ForEach(displayed) { m in
                        NavigationLink {
                            MemberDetailView(membershipID: m.id)
                        } label: {
                            MembershipCard(membership: m)
                        }
                        .listRowCard()
                    }
                }
                .listStyle(.plain)
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                TopBar(title: "MEMBERS", glassTint: Theme.members.opacity(0.9), topPadding: 20, bottomPadding: 20) {
                    RolePicker(color: Theme.members)
                }
            }
            .screenBackground("memView", fit: true, topOffset: 160)
        }
    }
}

// MARK: - Membership card
struct MembershipCard: View {
    let membership: Membership

    var body: some View {
        let color = Theme.color(for: membership.type)
        let b = membership.breakdown
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                IconBadge(systemName: membership.icon, color: color)
                VStack(alignment: .leading, spacing: 4) {
                    Text(membership.memberName).font(.headline)
                    HStack(spacing: 6) {
                        IDChip(text: membership.id, color: color)
                        StatusPill(text: membership.typeName, color: color)
                    }
                }
                Spacer()
                StatusPill(text: membership.status.rawValue, color: Theme.color(for: membership.status))
            }
            InfoRow(label: "Opening hours", value: membership.accessWindow.text)
            Divider()
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("ESTIMATED CHARGES").font(.system(size: 10, weight: .semibold)).foregroundColor(.gray)
                    Text(b.total.vnd).font(.system(size: 16, weight: .bold, design: .monospaced))
                }
                Spacer()
                StatusPill(text: b.outstanding == 0 ? "Paid" : "Due \(b.outstanding.vnd)",
                           color: b.outstanding == 0 ? Theme.success : Theme.warning)
            }
        }
    }
}

#Preview {
    MembersView().environmentObject(MembershipManager.preview())
}
