import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var familyService: FamilyService
    @EnvironmentObject var choreService: ChoreService
    @EnvironmentObject var rewardsService: RewardsService

    var body: some View {
        NavigationView {
            List {
                Text("Dashboard").font(.headline)

                Section {
                    Text("Children: \(familyService.children.count)")
                    Text("Pending approvals: \(choreService.pendingApprovals.count)")
                }
            }
            .navigationTitle("Dashboard")
            .task { await loadDashboardData() }
        }
    }

    private func loadDashboardData() async {
        // Load family + children
        await familyService.loadFamily()
        await familyService.loadChildren()

        // Load chores/assignments/completions + rewards/redemptions
        await choreService.loadAll()
        await rewardsService.loadAll()
    }
}
