
import Foundation
import Combine

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isAuthenticated = false
    @Published var currentUser: AppUser?
    @Published var isEmailVerified = false
    @Published var pendingVerificationEmail: String?

    private var authStateListener: Task<Void, Never>?

    private init() {}

    func initialize() async {
        // Load a persisted session if one exists
        if let savedId = UserDefaults.standard.string(forKey: "auth.userId"),
           let roleRaw = UserDefaults.standard.string(forKey: "auth.role"),
           let role = AppUser.Role(rawValue: roleRaw) {

            let displayName = UserDefaults.standard.string(forKey: "auth.displayName") ?? "User"
            let familyId = UserDefaults.standard.string(forKey: "auth.familyId")

            self.currentUser = AppUser(
                id: savedId,
                displayName: displayName,
                role: role,
                familyId: familyId
            )
            self.isAuthenticated = true
        } else {
            self.isAuthenticated = false
        }
    }

    // MARK: - Parent Email/Password Flow (stubs)

    func signUp(email: String, password: String, familyName: String) async throws {
        // TODO: Integrate with Supabase; for now, create a local session
        let newUser = AppUser(
            id: UUID().uuidString,
            displayName: familyName,
            role: .parent,
            familyId: UUID().uuidString
        )
        self.currentUser = newUser
        self.isAuthenticated = true
        self.pendingVerificationEmail = nil
        persistSession(user: newUser)
    }

    func signIn(email: String, password: String) async throws {
        // TODO: Replace with real auth
        let user = AppUser(
            id: UUID().uuidString,
            displayName: email,
            role: .parent,
            familyId: UUID().uuidString
        )
        self.currentUser = user
        self.isAuthenticated = true
        persistSession(user: user)
    }

    // MARK: - Child PIN Flow (stub)

    func signInChild(childId: String, pin: String) async throws {
        guard pin.count == 4, pin.allSatisfy({ $0.isNumber }) else {
            throw NSError(domain: "Auth",
                          code: 400,
                          userInfo: [NSLocalizedDescriptionKey: "PIN must be 4 digits"])
        }
        let user = AppUser(
            id: childId,
            displayName: "Child",
            role: .child,
            familyId: nil
        )
        self.currentUser = user
        self.isAuthenticated = true
        persistSession(user: user)
    }

    func signOut() {
        self.currentUser = nil
        self.isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "auth.userId")
        UserDefaults.standard.removeObject(forKey: "auth.role")
        UserDefaults.standard.removeObject(forKey: "auth.familyId")
        UserDefaults.standard.removeObject(forKey: "auth.displayName")
    }

    // MARK: - Helpers

    private func persistSession(user: AppUser) {
        UserDefaults.standard.set(user.id, forKey: "auth.userId")
        UserDefaults.standard.set(user.role.rawValue, forKey: "auth.role")
        if let familyId = user.familyId {
            UserDefaults.standard.set(familyId, forKey: "auth.familyId")
        }
        UserDefaults.standard.set(user.displayName, forKey: "auth.displayName")
    }
}
