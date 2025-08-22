// Auto-generated minimal stub; replace with your real implementation.
import Foundation
import Combine

struct Family: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var ownerUserId: String
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

final class FamilyService: ObservableObject {
    static let shared = FamilyService()
    @Published var currentFamily: Family? = Family(name: "Demo Family", ownerUserId: "owner")
    @Published var children: [AppUser] = []

    private init() {}

    func loadFamily() async throws {}
    func addChild(name: String, pin: String) async throws {
        let child = AppUser(role: .child, childPIN: pin, displayName: name)
        await MainActor.run { children.append(child) }
    }
    func updateChild(_ child: AppUser) async throws {}
    func deleteChild(_ child: AppUser) async throws {
        await MainActor.run { children.removeAll { $0.id == child.id } }
    }
}
