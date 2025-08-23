import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var choreService: ChoreService
    @EnvironmentObject var rewardsService: RewardsService
    @EnvironmentObject var familyService: FamilyService

    var body: some View {
        Group {
            if authService.isAuthenticated {
                if let user = authService.currentUser {
                    switch user.role {
                    case .parent:
                        ParentMainView()
                            .task {
                                await familyService.loadChildren()
                                await choreService.loadAll()
                                await rewardsService.loadAll()
                            }
                    case .child:
                        ChildMainView(childId: user.id)
                            .task {
                                await familyService.loadChildren()
                                await choreService.loadAll()
                                await rewardsService.loadAll()
                            }
                    }
                } else {
                    ProgressView("Loading profile…")
                }
            } else if authService.pendingVerificationEmail != nil {
                EmailVerificationView()
            } else {
                AuthenticationView()
            }
        }
    }
}
