// Auto-generated minimal stub; replace with your real implementation.
import Foundation
import Combine
import SwiftUI

enum RecurrenceRule: String, CaseIterable, Codable { case none, daily, weekly, monthly
    var displayName: String {
        switch self { case .none: return "One-time"; case .daily: return "Daily"; case .weekly: return "Weekly"; case .monthly: return "Monthly" }
    }
}

struct Chore: Identifiable, Codable {
    var id: String = UUID().uuidString
    var familyId: String
    var title: String
    var choreDescription: String? = nil
    var points: Int = 0
    var valueCents: Int? = nil
    var requiresPhoto: Bool = false
    var recurrenceRule: RecurrenceRule = .none
    var createdBy: String
}

enum ChoreStatus: String, Codable { case assigned = "Assigned", completed = "Completed", approved = "Approved", rejected = "Rejected"
    var color: Color { switch self { case .assigned: return .blue; case .completed: return .orange; case .approved: return .green; case .rejected: return .red } }
    var systemImage: String { switch self { case .assigned: return "circle"; case .completed: return "checkmark.circle"; case .approved: return "checkmark.seal"; case .rejected: return "xmark.circle" } }
}

struct ChoreInstance: Identifiable, Codable {
    var id: String = UUID().uuidString
    var choreId: String
    var dueAt: Date
    var assigneeChildId: String
    var status: ChoreStatus = .assigned
    var photoURL: String? = nil
    var completedAt: Date? = nil
    var approvedAt: Date? = nil
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var isOverdue: Bool { status == .assigned && dueAt < Date() }
    var isDueSoon: Bool { status == .assigned && dueAt.timeIntervalSinceNow < 3600 && dueAt > Date() }
}

struct DashboardSummary: Codable {
    var todayAssigned = 0
    var todayCompleted = 0
    var thisWeekAssigned = 0
    var thisWeekCompleted = 0
    var pendingApprovals = 0
    var childrenStats: [ChildStats] = []
    var totalPointsEarned = 0
}

struct ChildStats: Codable {
    var childId: String
    var displayName: String
    var completedChores: Int = 0
    var pendingChores: Int = 0
    var weeklyPoints: Int = 0
    var totalPoints: Int = 0
}

final class ChoreService: ObservableObject {
    static let shared = ChoreService()
    @Published var chores: [Chore] = []
    @Published var instances: [ChoreInstance] = []
    @Published var pendingApprovals: [ChoreInstance] = []
    private init() {}
    func loadChores() async throws {}
    func loadChoreInstances() async {}
    func createChore(_ chore: Chore, assignedTo childIds: [String]) async throws {}
    func completeChore(_ instance: ChoreInstance, photoURL: String? = nil) async throws {}
    func approveChore(_ instance: ChoreInstance) async throws {}
    func rejectChore(_ instance: ChoreInstance) async throws {}
    func getTodayInstances(for childId: String) -> [ChoreInstance] { instances.filter { $0.assigneeChildId == childId } }
    func getDashboardSummary() async -> DashboardSummary { DashboardSummary() }
}
