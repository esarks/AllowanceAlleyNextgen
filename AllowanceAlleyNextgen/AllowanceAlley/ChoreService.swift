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

    // Load everything needed for the dashboard
    func loadAll() async {
        guard let familyId = auth.currentUser?.familyId ?? auth.currentUser?.id else { return }
        async let a = loadChores(familyId: familyId)
        async let b = loadAssignments(familyId: familyId)
        async let c = loadCompletions(familyId: familyId)
        _ = await (a, b, c)
    }

    func loadChores(familyId: String) async {
        do { chores = try await db.fetchChores(familyId: familyId) } catch { print(error) }
    }

    func loadAssignments(familyId: String) async {
        do { assignments = try await db.fetchAssignments(familyId: familyId) } catch { print(error) }
    }

    func loadCompletions(familyId: String) async {
        do {
            completions = try await db.fetchCompletions(familyId: familyId)
            pendingApprovals = completions.filter { $0.status == .pending }
        } catch { print(error) }
    }

    // Create a chore and optional assignments
    func createChore(_ chore: Chore, assignedTo childIds: [String]) async throws {
        let created = try await db.createChore(chore)
        chores.append(created)

        for id in childIds {
            let a = try await db.assignChore(choreId: created.id, memberId: id, due: Date().addingTimeInterval(24*3600))
            assignments.append(a)
        }
    }

    // Child marks complete (optionally with photo URL you’ve stored in Storage)
    func completeChore(assignmentId: String, photoURL: String? = nil) async throws {
        let completion = ChoreCompletion(
            assignmentId: assignmentId,
            submittedBy: auth.currentUser?.id,
            photoURL: photoURL,
            status: .pending,
            completedAt: Date()
        )
        let saved = try await db.submitCompletion(completion)
        completions.insert(saved, at: 0)
        pendingApprovals.insert(saved, at: 0)
    }

    // Parent approves / rejects
    func approveCompletion(_ completion: ChoreCompletion) async throws {
        guard let reviewer = auth.currentUser?.id else { return }
        let updated = try await db.reviewCompletion(id: completion.id, status: "approved", reviewedBy: reviewer)
        replaceCompletion(updated)
    }

    func rejectCompletion(_ completion: ChoreCompletion) async throws {
        guard let reviewer = auth.currentUser?.id else { return }
        let updated = try await db.reviewCompletion(id: completion.id, status: "rejected", reviewedBy: reviewer)
        replaceCompletion(updated)
    }

    private func replaceCompletion(_ updated: ChoreCompletion) {
        if let i = completions.firstIndex(where: { $0.id == updated.id }) { completions[i] = updated }
        pendingApprovals.removeAll { $0.id == updated.id || updated.status != .pending }
        if updated.status == .pending { pendingApprovals.append(updated) }
    }

    // Utility used by ChildChoresView in some builds
    func getTodayAssignments(for memberId: String) -> [ChoreAssignment] {
        let cal = Calendar.current
        return assignments.filter { a in
            guard let due = a.dueDate else { return false }
            return cal.isDateInToday(due) && a.memberId == memberId
        }
    }
}
