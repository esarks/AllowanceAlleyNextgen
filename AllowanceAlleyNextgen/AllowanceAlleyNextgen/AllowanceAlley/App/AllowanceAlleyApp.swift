import SwiftUI
import Combine

@main
struct AllowanceAlleyApp: App {
    // Non-Observable singletons: keep as local constants (do not inject as EnvironmentObjects)
    private let coreDataStack = CoreDataStack.shared
    private let supabaseClient = SupabaseClient.shared

    // Observable services
    @StateObject private var authService = AuthService.shared
    @StateObject private var familyService = FamilyService.shared
    @StateObject private var choreService = ChoreService.shared
    @StateObject private var rewardsService = RewardsService.shared
    @StateObject private var notificationsService = NotificationsService.shared
    @StateObject private var imageStore = ImageStore.shared

    var body: some Scene {
        WindowGroup {
            // NOTE: We no longer declare ContentView in this file to avoid a duplicate type.
            // Use the existing ContentView defined elsewhere in your project.
            ContentView()
                .environmentObject(authService)
                .environmentObject(familyService)
                .environmentObject(choreService)
                .environmentObject(rewardsService)
                .environmentObject(notificationsService)
                .environmentObject(imageStore)
                .onAppear { setupServices() }
        }
    }

    private func setupServices() {
        authService.initialize()
        // notificationsService.requestPermissions()  // enable when ready
        _ = coreDataStack     // keep references alive if needed
        _ = supabaseClient
    }
}
