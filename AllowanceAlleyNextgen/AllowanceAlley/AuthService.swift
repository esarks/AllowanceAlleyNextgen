
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
        // Simulate loading persisted session
        if let savedId = UserDefaults.standard.string(forKey: "auth.userId"),
           let roleRaw = UserDefaults.standard.string(forKey: "auth.role"),
           let role = AppUser.Role(rawValue: roleRaw) {
            self.currentUser = AppUser(id: savedId, role: role, familyId: UserDefaults.standard.string(forKey: "auth.familyId"))
            self.isAuthenticated = true
        } else {
            self.isAuthenticated = false
        }
    }

    // MARK: - Parent Email/Password Flow (stubs)

    func signUp(email: String, password: String, familyName: String) async throws {
        // TODO: Integrate with Supabase; for now, create a local session
        let newUser = AppUser(id: UUID().uuidString, role: .parent, familyId: UUID().uuidString)
        self.currentUser = newUser
        self.isAuthenticated = true
        self.pendingVerificationEmail = nil
        persistSession(user: newUser)
    }

    func signIn(email: String, password: String) async throws {
        // TODO: Replace with real auth
        let user = AppUser(id: UUID().uuidString, role: .parent, familyId: UUID().uuidString)
        self.currentUser = user
        self.isAuthenticated = true
        persistSession(user: user)
    }

    // MARK: - Child PIN Flow (stub)

    func signInChild(childId: String, pin: String) async throws {
        guard pin.count == 4 else { throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "PIN must be 4 digits"]) }
        let user = AppUser(id: childId, role: .child, familyId: nil)
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
    }

    // MARK: - Helpers

    private func persistSession(user: AppUser) {
        UserDefaults.standard.set(user.id, forKey: "auth.userId")
        UserDefaults.standard.set(user.role.rawValue, forKey: "auth.role")
        if let familyId = user.familyId {
            UserDefaults.standard.set(familyId, forKey: "auth.familyId")
        }
    }
}

// MARK: - Minimal AppUser to compile

struct AppUser: Identifiable, Equatable {
    enum Role: String {
        case parent, child
    }
    let id: String
    let role: Role
    let familyId: String?
}
