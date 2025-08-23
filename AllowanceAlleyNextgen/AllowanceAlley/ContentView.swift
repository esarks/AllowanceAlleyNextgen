import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService

    var body: some View {
        Group {
            if authService.isAuthenticated {
                // If you have role on currentUser, route on it; otherwise default to parent UI
                if let user = authService.currentUser {
                    switch user.role {
                    case .parent:
                        ParentMainView()
                    case .child:
                        ChildMainView(childId: user.id)
                    }
                } else {
                    ParentMainView()  // fallback
                }
            } else if authService.pendingVerificationEmail != nil {
                EmailVerificationView()
            } else {
                AuthenticationView()
            }
        }
    }
}
