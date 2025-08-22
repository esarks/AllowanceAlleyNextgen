
import SwiftUI

/// Unified dashboard router that shows the proper dashboard for the current user.
struct DashboardView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var familyService: FamilyService

    var body: some View {
        Group {
            if let user = authService.currentUser {
                switch user.role {
                case .parent:
                    ParentDashboardView()
                case .child:
                    ChildDashboardView(childId: user.id)
                }
            } else {
                ProgressView("Loading…").task { await authService.initialize() }
            }
        }
    }
}
