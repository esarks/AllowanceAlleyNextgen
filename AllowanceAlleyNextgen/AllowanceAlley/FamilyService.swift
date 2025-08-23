import Foundation
import Combine

@MainActor
final class FamilyService: ObservableObject {
    static let shared = FamilyService()

    @Published private(set) var family: Family?
    @Published private(set) var children: [Child] = []

    private let auth = AuthService.shared
    private let db = DatabaseAPI.shared
    private init() {}

    func loadFamily() async {
        guard let userId = auth.currentUser?.id else { return }
        do { family = try await db.fetchFamily(for: userId) } catch { print(error) }
    }

    func loadChildren() async {
        guard let familyId = auth.currentUser?.familyId ?? auth.currentUser?.id else { return }
        do { children = try await db.fetchChildren(familyId: familyId) } catch { print(error) }
    }

    func createChild(name: String, birthdate: Date? = nil, pin: String? = nil) async throws {
        guard let familyId = auth.currentUser?.familyId ?? auth.currentUser?.id else { return }
        let created = try await db.createChild(familyId: familyId, displayName: name)
        children.append(created)
    }

    func updateChild(_ child: Child) async throws {
        let updated = try await db.updateChild(child)
        if let i = children.firstIndex(where: { $0.id == updated.id }) { children[i] = updated }
    }

    func deleteChild(_ child: Child) async throws {
        try await db.deleteChild(id: child.id)
        children.removeAll { $0.id == child.id }
    }
}
