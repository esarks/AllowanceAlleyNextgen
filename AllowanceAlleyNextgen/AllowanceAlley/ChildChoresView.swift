
import SwiftUI

struct ChildChoresView: View {
    let childId: String
    @EnvironmentObject var choreService: ChoreService
    @State private var assignments: [ChoreAssignment] = []
    @State private var completions: [ChoreCompletion] = []

    var body: some View {
        List {
            Section("To Do") {
                let pendingAssignments = assignments.filter { assignment in
                    !completions.contains { $0.assignmentId == assignment.id && $0.status != .rejected }
                }

                if pendingAssignments.isEmpty {
                    Text("No chores to do right now")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(pendingAssignments) { assignment in
                        ChildChoreRow(assignment: assignment, childId: childId)
                    }
                }
            }

            Section("Completed") {
                let completedAssignments = assignments.filter { assignment in
                    completions.contains { $0.assignmentId == assignment.id && $0.status == .approved }
                }

                if completedAssignments.isEmpty {
                    Text("No completed chores yet")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(completedAssignments) { assignment in
                        ChildChoreRow(assignment: assignment, childId: childId, isCompleted: true)
                    }
                }
            }

            Section("Pending Approval") {
                let pendingCompletions = completions.filter { $0.status == .pending && $0.submittedBy == childId }

                if pendingCompletions.isEmpty {
                    Text("No chores waiting for approval")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(pendingCompletions) { completion in
                        PendingChoreRow(completion: completion)
                    }
                }
            }
        }
        .navigationTitle("My Chores")
        .task {
            assignments = choreService.assignments.filter { $0.memberId == childId }
            completions = choreService.completions.filter { $0.submittedBy == childId }
        }
    }
}

struct ChildChoreRow: View {
    let assignment: ChoreAssignment
    let childId: String
    var isCompleted: Bool = false
    @EnvironmentObject var choreService: ChoreService
    @State private var isCompleting = false

    private var chore: Chore? {
        choreService.chores.first { $0.id == assignment.choreId }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(chore?.title ?? "Unknown Chore")
                    .font(.headline)
                    .strikethrough(isCompleted)
                    .foregroundColor(isCompleted ? .secondary : .primary)

                if let description = chore?.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                HStack {
                    if let dueDate = assignment.dueDate {
                        Text("Due: \(dueDate, style: .date)")
                            .font(.caption)
                            .foregroundColor(dueDate < Date() ? .red : .secondary)
                    }

                    if chore?.requirePhoto == true {
                        Label("Photo", systemImage: "camera.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }

                    Spacer()

                    if let points = chore?.points {
                        Text("\(points) pts")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
            }

            if !isCompleted {
                Button("Complete") {
                    isCompleting = true
                    Task {
                        try? await choreService.completeChore(assignment.id)
                        isCompleting = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isCompleting)
            }
        }
        .padding(.vertical, 4)
    }
}

struct PendingChoreRow: View {
    let completion: ChoreCompletion
    @EnvironmentObject var choreService: ChoreService

    private var assignment: ChoreAssignment? {
        choreService.assignments.first { $0.id == completion.assignmentId }
    }

    private var chore: Chore? {
        guard let assignment = assignment else { return nil }
        return choreService.chores.first { $0.id == assignment.choreId }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(chore?.title ?? "Unknown Chore")
                    .font(.headline)

                Text("Waiting for approval...")
                    .font(.caption)
                    .foregroundColor(.orange)

                if let completedAt = completion.completedAt {
                    Text("Submitted: \(completedAt, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "clock.fill")
                .foregroundColor(.orange)
        }
        .padding(.vertical, 4)
    }
}
