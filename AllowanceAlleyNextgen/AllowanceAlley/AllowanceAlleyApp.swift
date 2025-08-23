import SwiftUI
import Combine

@main
struct AllowanceAlleyApp: App {
    @StateObject private var authService = AuthService.shared
    @StateObject private var familyService = FamilyService.shared
    @StateObject private var choreService = ChoreService.shared
    @StateObject private var rewardsService = RewardsService.shared
    @StateObject private var notificationsService = NotificationsService.shared
    @StateObject private var imageStore = ImageStore.shared
    
    private let coreDataStack = CoreDataStack.shared
    private let supabase = AppSupabase.shared

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
                    setupServices()
                }
        }
    }
    
    private func setupServices() {
        Task {
            await authService.resetAuthenticationState()
            authService.initialize()
        }
        _ = coreDataStack
        _ = supabase
    }
}
