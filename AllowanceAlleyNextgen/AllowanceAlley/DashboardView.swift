import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var familyService: FamilyService
    @EnvironmentObject var choreService: ChoreService
    @EnvironmentObject var rewardsService: RewardsService
    
    @State private var summary = DashboardSummary()
    
    var body: some View {
        NavigationView {
            List {
                Text("Dashboard")
                Text("Children: \(familyService.children.count)")
                Text("Pending approvals: \(summary.pendingApprovals)")
            }
            .navigationTitle("Dashboard")
            .task { await loadDashboardData() }
        }
    }
    
    private func loadDashboardData() async {
        do {
            try await familyService.loadFamily()
            try await choreService.loadChores()
            try await choreService.loadAssignments()
            try await choreService.loadCompletions()
            try await rewardsService.loadRewards()
            try await rewardsService.loadRedemptions()
            summary = await choreService.getDashboardSummary()
        } catch {
            print("Failed to load dashboard data: \(error)")
        }
    }
}
