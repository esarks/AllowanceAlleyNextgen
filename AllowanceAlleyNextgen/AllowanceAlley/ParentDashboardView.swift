
import SwiftUI

struct ParentDashboardView: View {
    @EnvironmentObject var family: FamilyService
    @EnvironmentObject var chores: ChoreService
    @EnvironmentObject var rewards: RewardsService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Family").font(.headline)
                Text(family.family?.name ?? "—")
                Divider()
                Text("Members").font(.headline)
                ForEach(family.members, id: \ .id) { m in
                    HStack {
                        Text(m.childName ?? (m.userId ?? "Member"))
                        Spacer()
                        Text(m.role.rawValue.capitalized)
                    }
                    .padding(.vertical, 4)
                }
                Divider()
                Text("Chores: \(chores.chores.count) • Rewards: \(rewards.rewards.count)")
            }
            .padding()
        }
        .navigationTitle("Dashboard")
    }
}
