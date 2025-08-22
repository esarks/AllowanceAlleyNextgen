import SwiftUI

struct ParentChoresView: View {
    @EnvironmentObject var choreService: ChoreService
    @EnvironmentObject var familyService: FamilyService
    @State private var showingAddChore = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("View", selection: $selectedTab) {
                    Text("All Chores").tag(0)
                    Text("Assignments").tag(1)
                    Text("Completed").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    allChoresView
                        .tag(0)
                    
                    assignmentsView
                        .tag(1)
                    
                    completedView
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
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
                await loadData()
            }
        }
    }
    
    private var allChoresView: some View {
        List {
            if choreService.chores.isEmpty {
                ContentUnavailableView(
                    "No Chores Created",
                    systemImage: "list.bullet.clipboard",
                    description: Text("Create your first chore to get started with tracking family tasks.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(choreService.chores) { chore in
                    ChoreManagementRow(chore: chore)
                }
            }
        }
    }
    
    private var assignmentsView: some View {
        List {
            if choreService.assignments.isEmpty {
                ContentUnavailableView(
                    "No Active Assignments",
                    systemImage: "person.2.gobackward",
                    description: Text("Chores will appear here once you assign them to children.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(familyService.children) { child in
                    let childAssignments = choreService.assignments.filter { $0.memberId == child.id }
                    
                    if !childAssignments.isEmpty {
                        Section(child.name) {
                            ForEach(childAssignments) { assignment in
                                AssignmentRow(assignment: assignment)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var completedView: some View {
        List {
            let approvedCompletions = choreService.completions.filter { $0.status == .approved }
            
            if approvedCompletions.isEmpty {
                ContentUnavailableView(
                    "No Completed Chores",
                    systemImage: "checkmark.circle",
                    description: Text("Completed chores will appear here after you approve them.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(approvedCompletions.sorted { ($0.reviewedAt ?? Date.distantPast) > ($1.reviewedAt ?? Date.distantPast) }) { completion in
                    CompletedChoreRow(completion: completion)
                }
            }
        }
    }
    
    private func loadData() async {
        do {
            try await choreService.loadChores()
            try await choreService.loadAssignments()
            try await choreService.loadCompletions()
            try await familyService.loadFamily()
        } catch {
            print("Failed to load chore data: \(error)")
        }
    }
}

struct ChoreManagementRow: View {
    let chore: Chore
    @EnvironmentObject var choreService: ChoreService
    @EnvironmentObject var familyService: FamilyService
    @State private var showingAssignSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(chore.title)
                        .font(.headline)
                    
                    if let description = chore.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(chore.points) pts")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    if chore.requirePhoto {
                        Image(systemName: "camera.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            HStack {
                if let recurrence = chore.recurrence {
                    Label(recurrence.capitalized, systemImage: "repeat")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Assign") {
                    showingAssignSheet = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingAssignSheet) {
            AssignChoreSheet(chore: chore)
        }
    }
}

struct AssignmentRow: View {
    let assignment: ChoreAssignment
    @EnvironmentObject var choreService: ChoreService
    @EnvironmentObject var familyService: FamilyService
    
    private var chore: Chore? {
        choreService.chores.first { $0.id == assignment.choreId }
    }
    
    private var isOverdue: Bool {
        guard let dueDate = assignment.dueDate else { return false }
        return dueDate < Date()
    }
    
    private var isCompleted: Bool {
        choreService.completions.contains { completion in
            completion.assignmentId == assignment.id && completion.status == .approved
        }
    }
    
    private var isPending: Bool {
        choreService.completions.contains { completion in
            completion.assignmentId == assignment.id && completion.status == .pending
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(chore?.title ?? "Unknown Chore")
                    .font(.subheadline)
                    .strikethrough(isCompleted)
                
                if let dueDate = assignment.dueDate {
                    Text("Due: \(dueDate, style: .date)")
                        .font(.caption)
                        .foregroundColor(isOverdue ? .red : .secondary)
                }
            }
            
            Spacer()
            
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else if isPending {
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
            } else if isOverdue {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            }
        }
    }
}

struct CompletedChoreRow: View {
    let completion: ChoreCompletion
    @EnvironmentObject var choreService: ChoreService
    @EnvironmentObject var familyService: FamilyService
    
    private var assignment: ChoreAssignment? {
        choreService.assignments.first { $0.id == completion.assignmentId }
    }
    
    private var chore: Chore? {
        guard let assignment = assignment else { return nil }
        return choreService.chores.first { $0.id == assignment.choreId }
    }
    
    private var childName: String {
        guard let assignment = assignment else { return "Unknown" }
        return familyService.children.first { $0.id == assignment.memberId }?.name ?? "Unknown"
    }
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(chore?.title ?? "Unknown Chore")
                    .font(.subheadline)
                
                Text("Completed by \(childName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let reviewedAt = completion.reviewedAt {
                    Text("Approved \(reviewedAt, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let points = chore?.points {
                Text("+\(points) pts")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
        }
    }
}

struct AssignChoreSheet: View {
    let chore: Chore
    @EnvironmentObject var choreService: ChoreService
    @EnvironmentObject var familyService: FamilyService
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedChildren: Set<String> = []
    @State private var dueDate = Date().addingTimeInterval(86400) // Tomorrow
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Chore") {
                    Text(chore.title)
                        .font(.headline)
                    
                    if let description = chore.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Points")
                        Spacer()
                        Text("\(chore.points)")
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                    }
                }
                
                Section("Due Date") {
                    DatePicker("Due date", selection: $dueDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                }
                
                Section("Assign to") {
                    ForEach(familyService.children) { child in
                        Toggle(child.name, isOn: Binding(
                            get: { selectedChildren.contains(child.id) },
                            set: { isSelected in
                                if isSelected {
                                    selectedChildren.insert(child.id)
                                } else {
                                    selectedChildren.remove(child.id)
                                }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("Assign Chore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await assignChore() }
                    } label: {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("Assign")
                        }
                    }
                    .disabled(selectedChildren.isEmpty || isLoading)
                }
            }
        }
    }
    
    private func assignChore() async {
        isLoading = true
        
        // Create assignments for selected children
        for childId in selectedChildren {
            let assignment = ChoreAssignment(
                choreId: chore.id,
                memberId: childId,
                dueDate: dueDate
            )
            choreService.assignments.append(assignment)
        }
        
        isLoading = false
        dismiss()
    }
}