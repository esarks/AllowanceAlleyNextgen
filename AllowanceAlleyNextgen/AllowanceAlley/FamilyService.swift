import Foundation
import Combine

@MainActor
final class FamilyService: ObservableObject {
    static let shared = FamilyService()
    
    @Published var currentFamily: Family?
    @Published var children: [Child] = []
    @Published var familyMembers: [FamilyMember] = []
    
    private let supabaseClient = SupabaseClient.shared
    private let authService = AuthService.shared
    
    private init() {}
    
    func loadFamily() async throws {
        guard let userId = authService.currentUser?.id else { return }
        
        // Load family where user is owner
        if let family = try await supabaseClient.fetchFamily(id: userId) {
            currentFamily = family
        }
        
        // Load children
        children = try await supabaseClient.fetchChildren(parentUserId: userId)
    }
    
    func createChild(name: String, birthdate: Date?, pin: String) async throws {
        guard let userId = authService.currentUser?.id else {
            throw FamilyError.notAuthenticated
        }
        
        let child = Child(
            parentUserId: userId,
            name: name,
            birthdate: birthdate
        )
        
        let created = try await supabaseClient.createChild(child)
        children.append(created)
    }
    
    func updateChild(_ child: Child) async throws {
        // Implementation for updating child
        if let index = children.firstIndex(where: { $0.id == child.id }) {
            children[index] = child
        }
    }
    
    func deleteChild(_ child: Child) async throws {
        children.removeAll { $0.id == child.id }
    }
}

// Family Member Model for backward compatibility
public struct FamilyMember: Identifiable, Codable, Equatable {
    public var id: String
    public var familyId: String
    public var userId: String?
    public var childName: String?
    public var age: Int?
    public var role: UserRole
    public var createdAt: Date?
    
    public init(
        id: String = UUID().uuidString,
        familyId: String,
        userId: String? = nil,
        childName: String? = nil,
        age: Int? = nil,
        role: UserRole,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.familyId = familyId
        self.userId = userId
        self.childName = childName
        self.age = age
        self.role = role
        self.createdAt = createdAt
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
