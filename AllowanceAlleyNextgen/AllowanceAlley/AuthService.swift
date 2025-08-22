import Foundation
import Combine
import Supabase

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated = false
    @Published var currentUser: AppUser?
    @Published var currentSupabaseUser: User?
    @Published var isEmailVerified = false
    @Published var pendingVerificationEmail: String?
    
    private let supabase = AppSupabase.shared
    private var authStateListener: Task<Void, Never>?
    
    private init() {}
    
    func initialize() {
        Task {
            await checkAuthState()
            setupAuthStateListener()
        }
    }
    
    private func setupAuthStateListener() {
        authStateListener = Task {
            for await state in supabase.client.auth.authStateChanges {
                await handleAuthStateChange(state)
            }
        }
    }
    
    private func handleAuthStateChange(_ authState: AuthState) async {
        switch authState.event {
        case .signedIn:
            if let user = authState.session?.user {
                await loadUserProfile(supabaseUser: user)
            }
        case .signedOut:
            await signOutLocally()
        case .tokenRefreshed: break
        default: break
        }
    }
    
    private func checkAuthState() async {
        do {
            if let session = try await supabase.client.auth.session,
               let user = session.user {
                await loadUserProfile(supabaseUser: user)
            }
        } catch {
            print("Failed to check auth state: \(error)")
        }
    }
    
    func signUp(email: String, password: String, familyName: String) async throws {
        let response = try await supabase.client.auth.signUp(email: email, password: password)
        pendingVerificationEmail = email
        isEmailVerified = false
        if let user = response.user {
            currentSupabaseUser = user
            isEmailVerified = user.emailConfirmedAt != nil
            if isEmailVerified {
                try await createUserProfile(user: user, familyName: familyName)
            }
        }
    }
    
    func signIn(email: String, password: String) async throws {
        let response = try await supabase.client.auth.signIn(email: email, password: password)
        if let user = response.user {
            await loadUserProfile(supabaseUser: user)
        }
    }
    
    func signInChild(childId: String, pin: String) async throws {
        let child = AppUser(id: childId, role: .child, displayName: "Demo Child")
        currentUser = child
        isAuthenticated = true
    }
    
    func signOut() async throws {
        try await supabase.client.auth.signOut()
        await signOutLocally()
    }
    
    private func signOutLocally() async {
        currentUser = nil
        currentSupabaseUser = nil
        isAuthenticated = false
        isEmailVerified = false
        pendingVerificationEmail = nil
    }
    
    private func createUserProfile(user: User, familyName: String) async throws {
        let family = Family(ownerId: user.id.uuidString, name: familyName)
        let createdFamily = try await DatabaseAPI.shared.createFamily(family)
        let appUser = AppUser(id: user.id.uuidString, role: .parent, email: user.email, displayName: familyName + " Parent", familyId: createdFamily.id)
        currentUser = appUser
        currentSupabaseUser = user
        isAuthenticated = true
        pendingVerificationEmail = nil
    }
    
    private func loadUserProfile(supabaseUser: User) async {
        let appUser = AppUser(id: supabaseUser.id.uuidString, role: .parent, email: supabaseUser.email, displayName: "Parent")
        currentUser = appUser
        currentSupabaseUser = supabaseUser
        isAuthenticated = true
        isEmailVerified = supabaseUser.emailConfirmedAt != nil
        pendingVerificationEmail = nil
    }
    
    deinit { authStateListener?.cancel() }
}
