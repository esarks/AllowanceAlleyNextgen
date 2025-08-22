import Foundation
import Combine

@MainActor
final class ChoreService: ObservableObject {
    static let shared = ChoreService()
    
    @Published var chores: [Chore] = []
    @Published var assignments: [ChoreAssignment] = []
    @Published var completions: [ChoreCompletion] = []
    @Published var pendingApprovals: [ChoreCompletion] = []
    
    private let authService = AuthService.shared
    
    private init() {}
    
    func loadChores() async throws {
        guard let familyId = authService.currentUser?.familyId ?? authService.currentUser?.id else { return }
        chores = [
            Chore(familyId: familyId, title: "Make Bed", description: "Make your bed neatly every morning", points: 10, requirePhoto: false, parentUserId: authService.currentUser?.id ?? ""),
            Chore(familyId: familyId, title: "Take Out Trash", description: "Take the kitchen trash to the curb", points: 20, requirePhoto: true, parentUserId: authService.currentUser?.id ?? "")
        ]
    }
    
    func loadAssignments() async throws { assignments = [] }
    func loadCompletions() async throws {
        completions = []
        pendingApprovals = completions.filter { $0.status == .pending }
    }
    
    func createChore(_ chore: Chore, assignedTo childIds: [String]) async throws {
        chores.append(chore)
        for childId in childIds {
            let assignment = ChoreAssignment(choreId: chore.id, memberId: childId, dueDate: Date().adding(days: 1))
            assignments.append(assignment)
        }
    }
    
    func completeChore(_ assignmentId: String, photoURL: String? = nil) async throws {
        let completion = ChoreCompletion(assignmentId: assignmentId, submittedBy: authService.currentUser?.id, photoURL: photoURL, status: .pending, completedAt: Date())
        completions.append(completion)
        pendingApprovals.append(completion)
    }
    
    func approveCompletion(_ completion: ChoreCompletion) async throws {
        var updated = completion
        updated.status = .approved
        updated.reviewedBy = authService.currentUser?.id
        updated.reviewedAt = Date()
        if let index = completions.firstIndex(where: { $0.id == completion.id }) { completions[index] = updated }
        pendingApprovals.removeAll { $0.id == completion.id }
    }
    
    func rejectCompletion(_ completion: ChoreCompletion) async throws {
        var updated = completion
        updated.status = .rejected
        updated.reviewedBy = authService.currentUser?.id
        updated.reviewedAt = Date()
        if let index = completions.firstIndex(where: { $0.id == completion.id }) { completions[index] = updated }
        pendingApprovals.removeAll { $0.id == completion.id }
    }
    
    func getTodayAssignments(for childId: String) -> [ChoreAssignment] {
        assignments.filter { $0.memberId == childId && ($0.dueDate?.isToday ?? false) }
    }
    
    func getDashboardSummary() async -> DashboardSummary {
        var summary = DashboardSummary()
        summary.todayAssigned = assignments.filter { $0.dueDate?.isToday ?? false }.count
        summary.todayCompleted = completions.filter { $0.completedAt?.isToday ?? false }.count
        summary.thisWeekAssigned = assignments.filter { $0.dueDate?.isThisWeek ?? false }.count
        summary.thisWeekCompleted = completions.filter { $0.completedAt?.isThisWeek ?? false }.count
        summary.pendingApprovals = pendingApprovals.count
        return summary
    }
}
