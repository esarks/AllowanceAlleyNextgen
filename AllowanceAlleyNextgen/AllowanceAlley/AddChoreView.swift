
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
    @State private var selectedChildren: Set<String> = []
    @State private var error: String?

    var body: some View {
        NavigationView {
            Form {
                Section("Chore Details") {
                    TextField("Title", text: $title)
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)

                    HStack {
                        Text("Points")
                        Spacer()
                        Stepper("\(points)", value: $points, in: 1...100)
                    }

                    Toggle("Require photo proof", isOn: $requirePhoto)
                }

                Section("Assign to Children") {
                    if familyService.children.isEmpty {
                        Text("No children added yet")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(familyService.children) { child in
                            HStack {
                                Text(child.name)
                                Spacer()
                                if selectedChildren.contains(child.id) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedChildren.contains(child.id) {
                                    selectedChildren.remove(child.id)
                                } else {
                                    selectedChildren.insert(child.id)
                                }
                            }
                        }
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
                    Button("Save") {
                        saveChore()
                    }
                    .disabled(title.isEmpty || selectedChildren.isEmpty)
                }
            }
        }
    }

    private func saveChore() {
        guard let familyId = authService.currentUser?.familyId ?? authService.currentUser?.id,
              let parentUserId = authService.currentUser?.id else {
            error = "Authentication error"
            return
        }

        let chore = Chore(
            familyId: familyId,
            title: title,
            description: description.isEmpty ? nil : description,
            points: points,
            requirePhoto: requirePhoto,
            parentUserId: parentUserId
        )

        Task {
            do {
                try await choreService.createChore(chore, assignedTo: Array(selectedChildren))
                dismiss()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}
