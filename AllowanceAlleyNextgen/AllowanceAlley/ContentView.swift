import SwiftUI

struct ContentView: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var familyService: FamilyService
    @EnvironmentObject var choreService: ChoreService
    @EnvironmentObject var rewardsService: RewardsService

    var body: some View {
        Group {
            if auth.isAuthenticated, let user = auth.currentUser {
                MainShell(user: user)
                    .task(id: user.id) {
                        // Post-login preload
                        await familyService.ensureFamilyExists()
                        let famId = familyService.family?.id ?? user.familyId
                        if let famId {
                            await familyService.loadMembers()
                            await choreService.loadAll(for: famId)
                            await rewardsService.loadAll(familyId: famId)
                        }
                    }
            } else if auth.pendingVerificationEmail != nil {
                // 6-digit code screen
                EmailVerificationView()
            } else {
                // Email → "Send 6-digit code"
                AuthenticationView()
            }
        }
    }
}

struct MainShell: View {
    let user: AppUser

    var body: some View {
        switch user.role {
        case .parent:
            TabView {
                NavigationStack {
                    ParentDashboardView()
                }
                .tabItem { Label("Dashboard", systemImage: "house") }

                NavigationStack {
                    ParentChoresView()
                }
                .tabItem { Label("Chores", systemImage: "checkmark.circle") }

                NavigationStack {
                    ParentRewardsView()
                }
                .tabItem { Label("Rewards", systemImage: "gift") }

                NavigationStack {
                    ParentSettingsView()
                }
                .tabItem { Label("Settings", systemImage: "gear") }
            }
        case .child:
            ChildMainView(childId: user.id)
        }
    }
}

// MARK: - Parent Views

struct ParentChoresView: View {
    @EnvironmentObject var choreService: ChoreService
    @EnvironmentObject var familyService: FamilyService
    @State private var showAddChore = false
    @State private var showApprovals = false

    var body: some View {
        List {
            Section("Quick Actions") {
                Button("Add Chore") { showAddChore = true }
                Button("Review Approvals (\(choreService.pendingApprovals.count))") { 
                    showApprovals = true 
                }
            }
            
            Section("All Chores") {
                ForEach(choreService.chores) { chore in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(chore.title).font(.headline)
                        if let description = chore.description {
                            Text(description).font(.caption).foregroundColor(.secondary)
                        }
                        Text("\(chore.points) points").font(.caption).foregroundColor(.blue)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("Chores")
        .sheet(isPresented: $showAddChore) {
            AddChoreView()
        }
        .sheet(isPresented: $showApprovals) {
            ApprovalsView()
        }
    }
}

struct ParentRewardsView: View {
    @EnvironmentObject var rewardsService: RewardsService
    @State private var showAddReward = false

    var body: some View {
        List {
            Section("Quick Actions") {
                Button("Add Reward") { showAddReward = true }
            }
            
            Section("Available Rewards") {
                ForEach(rewardsService.rewards) { reward in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(reward.name).font(.headline)
                            Text("\(reward.costPoints) points")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("Available").foregroundColor(.green)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("Rewards")
        .sheet(isPresented: $showAddReward) {
            AddRewardView()
        }
    }
}
