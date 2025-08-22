
import SwiftUI

struct ParentChoresView: View {
    @EnvironmentObject var choreService: ChoreService
    @EnvironmentObject var familyService: FamilyService
    @State private var showingAddChore = false

    var body: some View {
        NavigationView {
            List {
                Section("Active Chores") {
                    if choreService.chores.isEmpty {
                        Text("No chores created yet")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(choreService.chores) { chore in
                            ChoreRow(chore: chore)
                        }
                    }
                }

                Section("Assignments") {
                    if choreService.assignments.isEmpty {
                        Text("No assignments yet")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(choreService.assignments) { assignment in
                            AssignmentRow(assignment: assignment)
                        }
                    }
                }
            }
            .navigationTitle("Chores")
            .toolbar {
                Button {
                    showingAddChore = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingAddChore) {
                AddChoreView()
            }
            .task {
                try? await choreService.loadChores()
                try? await choreService.loadAssignments()
            }
        }
    }
}

struct ChoreRow: View {
    let chore: Chore

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(chore.title)
                    .font(.headline)
                Spacer()
                Text("\(chore.points) pts")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }

            if let description = chore.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                if chore.requirePhoto {
                    Label("Photo required", systemImage: "camera.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

struct AssignmentRow: View {
    let assignment: ChoreAssignment
    @EnvironmentObject var choreService: ChoreService
    @EnvironmentObject var familyService: FamilyService

    private var choreName: String {
        choreService.chores.first { $0.id == assignment.choreId }?.title ?? "Unknown Chore"
    }

    private var childName: String {
        familyService.children.first { $0.id == assignment.memberId }?.name ?? "Unknown Child"
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(choreName)
                    .font(.headline)
                Text("Assigned to: \(childName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let dueDate = assignment.dueDate {
                    Text("Due: \(dueDate, style: .date)")
                        .font(.caption)
                        .foregroundColor(dueDate < Date() ? .red : .secondary)
                }
            }
            Spacer()
        }
    }
}
