import SwiftUI

@main
struct AllowanceAlleyApp: App {
    // Own the singletons here and inject as environment objects
    @StateObject private var authService = AuthService.shared
    @StateObject private var familyService = FamilyService.shared
    @StateObject private var choreService = ChoreService.shared
    @StateObject private var rewardsService = RewardsService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(familyService)
                .environmentObject(choreService)
                .environmentObject(rewardsService)
                .onAppear {
                    authService.initialize()
                }
        }
    }
}
