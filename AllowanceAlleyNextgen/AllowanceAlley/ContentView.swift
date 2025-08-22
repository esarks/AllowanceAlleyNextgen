
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var familyService: FamilyService
    @EnvironmentObject var choreService: ChoreService
    @EnvironmentObject var rewardsService: RewardsService

    var body: some View {
        Group {
            if authService.isAuthenticated {
                if let user = authService.currentUser {
                    switch user.role {
                    case .parent:
                        ParentTabView()
                    case .child:
                        ChildTabView(childId: user.id)
                    }
                } else {
                    ProgressView("Loading user…")
                        .task { await authService.initialize() }
                }
            } else if authService.pendingVerificationEmail != nil {
                EmailVerificationView()
            } else {
                AuthenticationView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: authService.isAuthenticated)
    }
}

struct ParentTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

            ParentChoresView()
                .tabItem {
                    Image(systemName: "list.clipboard.fill")
                    Text("Chores")
                }

            ParentRewardsView()
                .tabItem {
                    Image(systemName: "gift.fill")
                    Text("Rewards")
                }

            ApprovalsView()
                .tabItem {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Approvals")
                }
        }
    }
}

struct ChildTabView: View {
    let childId: String

    var body: some View {
        TabView {
            ChildHomeView(childId: childId)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

            ChildChoresView(childId: childId)
                .tabItem {
                    Image(systemName: "list.clipboard.fill")
                    Text("Chores")
                }

            ChildRewardsView(childId: childId)
                .tabItem {
                    Image(systemName: "gift.fill")
                    Text("Rewards")
                }

            ChildProfileView(childId: childId)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
    }
}
