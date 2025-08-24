import SwiftUI

// MARK: - Parent Main

struct ParentMainView: View {
    var body: some View {
        TabView {
            NavigationStack {
                ParentDashboardView()
            }
            .tabItem { Label("Home", systemImage: "house.fill") }

            NavigationStack {
                ReportsView()
            }
            .tabItem { Label("Reports", systemImage: "chart.bar.fill") }

            NavigationStack {
                ParentSettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

// MARK: - Child Main

struct ChildMainView: View {
    let childId: String

    var body: some View {
        TabView {
            NavigationStack {
                ChildChoresView(childId: childId)
            }
            .tabItem { Label("Chores", systemImage: "checklist") }

            NavigationStack {
                ChildRewardsView(childId: childId)
            }
            .tabItem { Label("Rewards", systemImage: "gift.fill") }

            NavigationStack {
                ChildSettingsView(childId: childId)
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

// MARK: - Child Chores

struct ChildChoresView: View {
    let childId: String
    @EnvironmentObject var choreService: ChoreService
    @EnvironmentObject var familyService: FamilyService
    @State private var todays: [ChoreAssignment] = []
    @State private var error: String?

    var body: some View {
        List {
            if let error {
                Text(error).foregroundColor(.red)
            }
            
            Section("Today's Chores") {
                if todays.isEmpty {
                    Text("No chores due today 🎉")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(todays, id: \.id) { assignment in
                        ChoreAssignmentRow(assignment: assignment, childId: childId)
                    }
                }
            }
            
            Section("All My Chores") {
                ForEach(myAssignments, id: \.id) { assignment in
                    ChoreAssignmentRow(assignment: assignment, childId: childId)
                }
            }
        }
        .navigationTitle("My Chores")
        .task { await loadChores() }
        .refreshable { await loadChores() }
    }

    private var myAssignments: [ChoreAssignment] {
        choreService.assignments.filter { $0.memberId == childId }
    }

    private func loadChores() async {
        guard let familyId = familyService.family?.id else {
            error = "No family context"
            return
        }
        
        await choreService.loadAll(for: familyId)
        todays = choreService.getTodayAssignments(for: childId)
    }

    private func choreTitle(for choreId: String) -> String {
        choreService.chores.first(where: { $0.id == choreId })?.title ?? "Chore"
    }
}

struct ChoreAssignmentRow: View {
    let assignment: ChoreAssignment
    let childId: String
    @EnvironmentObject var choreService: ChoreService
    @State private var isCompleting = false
    @State private var error: String?

    private var chore: Chore? {
        choreService.chores.first(where: { $0.id == assignment.choreId })
    }

    private var isCompleted: Bool {
        choreService.completions.contains { completion in
            completion.assignmentId == assignment.id && completion.status != .rejected
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(chore?.title ?? "Unknown Chore")
                    .font(.headline)
                
                if let description = chore?.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    if let due = assignment.dueDateAsDate {
                        Text("Due: \(due.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    if let points = chore?.points {
                        Text("\(points) points")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
            
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Button("Complete") {
                    Task { await completeChore() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isCompleting)
            }
        }
        .padding(.vertical, 2)
    }

    private func completeChore() async {
        isCompleting = true
        defer { isCompleting = false }
        
        do {
            try await choreService.completeChore(assignmentId: assignment.id)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
