import SwiftUI

struct AddChoreView: View {
    @EnvironmentObject var choreService: ChoreService
    @EnvironmentObject var familyService: FamilyService
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var points = 10
    @State private var requirePhoto = false
    @State private var recurrence = "None"
    @State private var selectedChildren: Set<String> = []
    @State private var error: String?
    @State private var isLoading = false
    
    private let recurrenceOptions = ["None", "Daily", "Weekly", "Monthly"]
    
    private var isFormValid: Bool {
        !title.isEmpty && !selectedChildren.isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Chore Details") {
                    TextField("Chore title", text: $title)
                        .autocapitalization(.words)
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3)
                    
                    HStack {
                        Text("Points reward")
                        Spacer()
                        Stepper("\(points)", value: $points, in: 1...100, step: 5)
                    }
                    
                    Toggle("Require photo proof", isOn: $requirePhoto)
                }
                
                Section("Recurrence") {
                    Picker("Repeat", selection: $recurrence) {
                        ForEach(recurrenceOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                }
                
                Section("Assign to Children") {
                    if familyService.children.isEmpty {
                        VStack(spacing: 8) {
                            Text("No children added yet")
                                .foregroundColor(.secondary)
                            Button("Add a child first") {
                                dismiss()
                                // TODO: Navigate to add child
                            }
                            .font(.caption)
                        }
                        .padding(.vertical, 8)
                    } else {
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
                
                Section("Examples") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Easy chores (5-15 points):")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        Text("Make bed, put dishes away, feed pet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("Medium chores (15-30 points):")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        Text("Take out trash, vacuum room, load dishwasher")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("Hard chores (30+ points):")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        Text("Mow lawn, deep clean bathroom, organize closet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let error {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("Add Chore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await saveChore() }
                    } label: {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
        }
    }
    
    private func saveChore() async {
        isLoading = true
        error = nil
        
        guard let familyId = authService.currentUser?.familyId ?? authService.currentUser?.id,
              let parentUserId = authService.currentUser?.id else {
            error = "Authentication error"
            isLoading = false
            return
        }
        
        let chore = Chore(
            familyId: familyId,
            title: title,
            description: description.isEmpty ? nil : description,
            points: points,
            requirePhoto: requirePhoto,
            recurrence: recurrence == "None" ? nil : recurrence.lowercased(),
            parentUserId: parentUserId
        )
        
        do {
            try await choreService.createChore(chore, assignedTo: Array(selectedChildren))
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
}