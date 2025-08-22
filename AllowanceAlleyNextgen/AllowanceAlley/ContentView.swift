import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var familyService: FamilyService
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                if let user = authService.currentUser {
                    switch user.role {
                    case .parent: DashboardView()
                    case .child: TodayView(childId: user.id)
                    }
                } else {
                    Text("Loading user data...").onAppear { Task { try? await authService.signOut() } }
                }
            } else if authService.pendingVerificationEmail != nil {
                EmailVerificationView()
            } else {
                AuthenticationView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authService.isAuthenticated)
    }
}

// Minimal TodayView to satisfy compiler
struct TodayView: View {
    let childId: String
    var body: some View {
        Text("Today's chores for child \(childId)").padding()
    }
}

// The rest of Authentication, EmailVerification, etc. come from the original split.
