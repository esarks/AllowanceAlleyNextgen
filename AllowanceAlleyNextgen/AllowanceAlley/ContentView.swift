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
                        DashboardView()
                    case .child:
                        // ✅ TodayView now requires childId
                        TodayView(childId: user.id)
                    }
                } else {
                    // Fallback if user hasn’t loaded yet
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
