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
            await refreshSession()
            startAuthListener()
        }
    }
    func resetAuthenticationState() async { await signOutLocally() }
    deinit { authStateListener?.cancel() }

    func signUp(email: String, password: String, familyName: String) async throws {
        let response = try await supabase.client.auth.signUp(email: email, password: password)
        let user = response.user
        pendingVerificationEmail = email
        isEmailVerified = (user.emailConfirmedAt != nil)
        if isEmailVerified { try await createUserProfile(user: user, familyName: familyName) }
        else { currentSupabaseUser = user; isAuthenticated = false }
    }
    func signIn(email: String, password: String) async throws {
        let response = try await supabase.client.auth.signIn(email: email, password: password)
        let user = response.user
        await loadUserProfile(supabaseUser: user)
    }
    func signInChild(childId: String, pin: String) async throws {
        guard pin.count == 4, pin.allSatisfy(\.isNumber) else { throw AuthError.invalidPin }
        let child = AppUser(id: childId, role: .child, displayName: "Child User")
        currentUser = child; currentSupabaseUser = nil; isAuthenticated = true; isEmailVerified = true; pendingVerificationEmail = nil
    }
    func signOut() async throws { try await supabase.client.auth.signOut(); await signOutLocally() }

    private func refreshSession() async {
        do { let session = try await supabase.client.auth.session; await applySession(session) }
        catch { await signOutLocally() }
    }
    private func applySession(_ session: Session) async { await loadUserProfile(supabaseUser: session.user) }
    private func startAuthListener() {
        authStateListener?.cancel()
        authStateListener = Task { [weak self] in
            guard let self else { return }
            do { for try await _ in self.supabase.client.auth.authStateChanges { await self.refreshSession() } } catch {}
        }
    }
    private func signOutLocally() async {
        currentUser = nil; currentSupabaseUser = nil; isAuthenticated = false; isEmailVerified = false; pendingVerificationEmail = nil
    }
    private func createUserProfile(user: User, familyName: String) async throws {
        let family = Family(ownerId: user.id.uuidString, name: familyName)
        let createdFamily = try await DatabaseAPI.shared.createFamily(family)
        let appUser = AppUser(id: user.id.uuidString, role: .parent, email: user.email, displayName: "\(familyName) Parent", familyId: createdFamily.id)
        currentUser = appUser; currentSupabaseUser = user; isAuthenticated = true; pendingVerificationEmail = nil; isEmailVerified = (user.emailConfirmedAt != nil)
    }
    private func loadUserProfile(supabaseUser: User) async {
        let appUser = AppUser(id: supabaseUser.id.uuidString, role: .parent, email: supabaseUser.email, displayName: "Parent")
        currentUser = appUser; currentSupabaseUser = supabaseUser; isAuthenticated = true; isEmailVerified = (supabaseUser.emailConfirmedAt != nil); pendingVerificationEmail = nil
    }
}
enum AuthError: LocalizedError {
    case invalidPin, childNotFound
    var errorDescription: String? {
        switch self { case .invalidPin: return "Please enter a valid 4-digit PIN"; case .childNotFound: return "Child not found" }
    }
}