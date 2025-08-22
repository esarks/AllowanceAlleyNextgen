// Auto-generated minimal stub; replace with your real implementation.
import Foundation
import Combine

enum UserRole: String, Codable { case parent = "Parent", child = "Child" }

struct AppUser: Identifiable, Codable {
    var id: String = UUID().uuidString
    var role: UserRole
    var email: String? = nil
    var childPIN: String? = nil
    var displayName: String
    var avatarURL: String? = nil
    var updatedAt: Date = Date()
}

final class AuthService: ObservableObject {
    static let shared = AuthService()
    @Published var isAuthenticated = false
    @Published var currentUser: AppUser? = nil

    private init() {}

    func signIn(email: String, password: String) async throws {
        // TODO: integrate with Supabase auth
        await MainActor.run {
            self.currentUser = AppUser(role: .parent, email: email, displayName: "Parent")
            self.isAuthenticated = True
        }
    }

    func signOut() async throws {
        await MainActor.run {
            self.currentUser = nil
            self.isAuthenticated = False
        }
    }
}
