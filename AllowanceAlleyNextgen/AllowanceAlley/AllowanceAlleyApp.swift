import SwiftUI

@main
struct AllowanceAlleyApp: App {
    @StateObject private var authService          = AuthService.shared
    @StateObject private var familyService        = FamilyService.shared
    @StateObject private var choreService         = ChoreService.shared
    @StateObject private var rewardsService       = RewardsService.shared
    @StateObject private var notificationsService = NotificationsService.shared
    @StateObject private var imageStore           = ImageStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(familyService)
                .environmentObject(choreService)
                .environmentObject(rewardsService)
                .environmentObject(notificationsService)
                .environmentObject(imageStore)
                .onAppear {
                    authService.initialize()
                }
        }
    }
}
