import SwiftUI

@main
struct AllowanceAlleyApp: App {
    // Use singletons; their initializers are private
    @StateObject private var auth = AuthService.shared
    @StateObject private var familyService = FamilyService.shared
    @StateObject private var choreService = ChoreService.shared
    @StateObject private var rewardsService = RewardsService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(auth)
                .environmentObject(familyService)
                .environmentObject(choreService)
                .environmentObject(rewardsService)
                .onAppear {
                    // If initialize() is async in your codebase, wrap with Task { await auth.initialize() }
                    auth.initialize()
                }
        }
    }
}
