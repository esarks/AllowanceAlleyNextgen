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
    private let supabaseClient = SupabaseClient.shared

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
        authService.initialize()
        // Keep references alive
        _ = coreDataStack
        _ = supabaseClient
    }
}
