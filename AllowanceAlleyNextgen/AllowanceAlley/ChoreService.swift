import Foundation
import Combine

@MainActor
final class ChoreService: ObservableObject {
    static let shared = ChoreService()

    @Published private(set) var chores: [Chore] = []
    @Published private(set) var assignments: [ChoreAssignment] = []
    @Published private(set) var completions: [ChoreCompletion] = []
    @Published private(set) var pendingApprovals: [ChoreCompletion] = []

    private let auth = AuthService.shared
    private let db = DatabaseAPI.shared
    private init() {}

    func loadAll(for familyId: String) async {
        async let a = loadChores(familyId: familyId)
        async let b = loadAssignments(familyId: familyId)
        async let c = loadCompletions(familyId: familyId)
        _ = await (a, b, c)
    }

    func loadChores(familyId: String) async {
        do { chores = try await db.fetchChores(familyId: familyId) } catch { print(error) }
    }

    func loadAssignments(familyId: String) async {
        do { assignments = try await db.fetchAssignmentsForFamily(familyId: familyId) } catch { print(error) }
    }

    func loadCompletions(familyId: String) async {
        do {
            completions = try await db.fetchCompletionsForFamily(familyId: familyId)
            pendingApprovals = completions.filter { $0.status == .pending }
        } catch { print(error) }
    }

    func createChore(familyId: String, title: String, description: String?, points: Int, requirePhoto: Bool, recurrence: String?) async throws -> Chore {
        guard let parentId = auth.currentUser?.id else { throw NSError(domain: "Auth", code: 401) }
        let created = try await db.createChore(familyId: familyId, title: title, description: description, points: points, requirePhoto: requirePhoto, recurrence: recurrence, parentUserId: parentId)
        chores.append(created)
        return created
    }

    func assignChore(choreId: String, memberId: String, due: Date?) async throws {
        let a = try await db.assignChore(choreId: choreId, memberId: memberId, due: due)
        assignments.append(a)
    }

    func completeChore(assignmentId: String, photoURL: String? = nil) async throws {
        let submittedBy = auth.currentUser?.id
        let saved = try await db.submitCompletion(assignmentId: assignmentId, submittedBy: submittedBy, photoURL: photoURL)
        completions.insert(saved, at: 0)
        pendingApprovals.insert(saved, at: 0)
    }

    func approveCompletion(_ completion: ChoreCompletion) async throws {
        guard let reviewer = auth.currentUser?.id else { return }
        let updated = try await db.reviewCompletion(id: completion.id, status: .approved, reviewedBy: reviewer)
        replaceCompletion(updated)
    }

    func rejectCompletion(_ completion: ChoreCompletion) async throws {
        guard let reviewer = auth.currentUser?.id else { return }
        let updated = try await db.reviewCompletion(id: completion.id, status: .rejected, reviewedBy: reviewer)
        replaceCompletion(updated)
    }

    private func replaceCompletion(_ updated: ChoreCompletion) {
        if let i = completions.firstIndex(where: { $0.id == updated.id }) { completions[i] = updated }
        pendingApprovals.removeAll { $0.id == updated.id || updated.status != .pending }
        if updated.status == .pending { pendingApprovals.append(updated) }
    }

    // --- Helper used by ChildChoresView ---
    func getTodayAssignments(for memberId: String) -> [ChoreAssignment] {
        let cal = Calendar(identifier: .iso8601)
        return assignments.filter { a in
            a.memberId == memberId && (a.dueDateAsDate.map { cal.isDateInToday($0) } ?? false)
        }
    }
}
