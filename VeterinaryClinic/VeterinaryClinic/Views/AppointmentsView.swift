import SwiftUI

struct AppointmentsView: View {
    @EnvironmentObject var manager: ClinicManager
    @State private var searchText = ""
    @State private var filter: AppointmentType? = nil

    var displayed: [Appointment] { manager.search(searchText, type: filter) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchField(placeholder: "Search pet, owner, ID...", text: $searchText)

                Picker("Type", selection: $filter) {
                    Text("All").tag(AppointmentType?.none)
                    Text("Routine").tag(AppointmentType?.some(.routine))
                    Text("Vaccine").tag(AppointmentType?.some(.vaccination))
                    Text("Emergency").tag(AppointmentType?.some(.emergency))
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

                RoleBanner()

                List {
                    if displayed.isEmpty {
                        EmptyHint(systemImage: "magnifyingglass", text: "No appointments found.").listRowCard()
                    }
                    ForEach(displayed) { a in
                        NavigationLink {
                            AppointmentDetailView(appointmentID: a.id)
                        } label: {
                            AppointmentCard(appointment: a)
                        }
                        .listRowCard(fill: a.type == .emergency ? Theme.emergency.opacity(0.08) : Theme.cardFill)
                    }
                }
                .listStyle(.plain)
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                TopBar(title: "APPOINTMENTS", glassTint: Theme.appointments.opacity(0.9), topPadding: 20, bottomPadding: 20) {
                    RolePicker(color: Theme.appointments)
                }
            }
            .screenBackground("apptView", fit: true, topOffset: 210)
        }
    }
}

// MARK: - Appointment card
struct AppointmentCard: View {
    let appointment: Appointment

    var body: some View {
        let a = appointment
        let color = Theme.color(for: a.type)
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                IconBadge(systemName: a.icon, color: color)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: a.pet.species.icon).foregroundColor(.gray).font(.system(size: 13))
                        Text(a.pet.name).font(.headline)
                    }
                    HStack(spacing: 6) {
                        IDChip(text: a.id, color: color)
                        Text(a.owner.name).font(.system(size: 12)).foregroundColor(.gray)
                    }
                }
                Spacer()
                StatusPill(text: a.status.rawValue, color: Theme.color(for: a.status))
            }
            InfoRow(label: a.typeName, value: a.scheduledDate.dateTimeText)
            Divider()
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("ESTIMATED CHARGES").font(.system(size: 10, weight: .semibold)).foregroundColor(.gray)
                    Text(a.estimatedCharges.vnd).font(.system(size: 16, weight: .bold, design: .monospaced))
                }
                Spacer()
                if a.type == .emergency { StatusPill(text: "PRIORITY", color: Theme.emergency) }
                if a.chargesLocked { StatusPill(text: "Charges locked", color: Theme.charges) }
            }
        }
    }
}

#Preview {
    AppointmentsView().environmentObject(ClinicManager.preview())
}
