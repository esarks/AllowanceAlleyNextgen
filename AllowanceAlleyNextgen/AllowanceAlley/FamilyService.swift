
import Foundation
import Combine

@MainActor
final class FamilyService: ObservableObject {
    static let shared = FamilyService()

    @Published private(set) var family: Family?
    @Published private(set) var members: [FamilyMember] = []

    private let auth = AuthService.shared
    private let db = DatabaseAPI.shared
    private init() {}

    func ensureFamilyExists(named defaultName: String = "My Family") async {
        guard let userId = auth.currentUser?.id else { return }
        do {
            if let fam = try await db.fetchFamilyByOwner(ownerId: userId) {
                self.family = fam
            } else {
                self.family = try await db.createFamily(name: defaultName, ownerId: userId)
            }
        } catch {
            print("ensureFamilyExists error:", error)
        }
    }

    func loadMembers() async {
        guard let familyId = family?.id ?? auth.currentUser?.familyId else { return }
        do { members = try await db.listFamilyMembers(familyId: familyId) } catch { print(error) }
    }

    func addChild(_ name: String, age: Int?) async throws {
        guard let familyId = family?.id ?? auth.currentUser?.familyId else { return }
        let created = try await db.createChildMember(familyId: familyId, childName: name, age: age)
        members.append(created)
    }
}
