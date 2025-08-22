import Foundation
import Combine

@MainActor
final class FamilyService: ObservableObject {
    static let shared = FamilyService()
    
    @Published var currentFamily: Family?
    @Published var children: [Child] = []
    @Published var familyMembers: [FamilyMember] = []
    
    private let authService = AuthService.shared
    
    private init() {}
    
    func loadFamily() async throws {
        guard let userId = authService.currentUser?.id else { return }
        if let family = try await DatabaseAPI.shared.fetchFamily(id: userId) {
            currentFamily = family
        }
        children = try await DatabaseAPI.shared.fetchChildren(parentUserId: userId)
    }
    
    func createChild(name: String, birthdate: Date?, pin: String) async throws {
        guard let userId = authService.currentUser?.id else { throw FamilyError.notAuthenticated }
        let child = Child(parentUserId: userId, name: name, birthdate: birthdate)
        let created = try await DatabaseAPI.shared.createChild(child)
        children.append(created)
    }
    
    func updateChild(_ child: Child) async throws {
        if let index = children.firstIndex(where: { $0.id == child.id }) {
            children[index] = child
        }
    }
    
    func deleteChild(_ child: Child) async throws {
        children.removeAll { $0.id == child.id }
    }
}

enum FamilyError: LocalizedError {
    case notAuthenticated
    case familyNotFound
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated"
        case .familyNotFound:
            return "Family not found"
        }
    }
}
