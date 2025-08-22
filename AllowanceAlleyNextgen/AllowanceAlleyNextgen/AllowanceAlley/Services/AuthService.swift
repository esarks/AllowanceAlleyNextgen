import Foundation
import Combine

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isAuthenticated: Bool = false
    @Published var currentUser: AppUser? = nil

    private init() {}

    // Call from App on launch
    func initialize() {
        // e.g., restore session if available
    }

    // Email/password parent sign up (stub for now)
    func signUp(email: String, password: String, familyName: String) async throws {
        // TODO: integrate with Supabase auth + family creation
        self.currentUser = AppUser(role: .parent, email: email, displayName: "Parent")
        self.isAuthenticated = true
    }

    // Email/password sign in (stub)
    func signIn(email: String, password: String) async throws {
        self.currentUser = AppUser(role: .parent, email: email, displayName: "Parent")
        self.isAuthenticated = true
    }

    // Child sign in by PIN (stub)
    func signInChild(childId: String, pin: String) async throws {
        self.currentUser = AppUser(id: childId, role: .child, childPIN: pin, displayName: "Child")
        self.isAuthenticated = true
    }

    func signOut() async throws {
        self.currentUser = nil
        self.isAuthenticated = false
    }
}
