import SwiftUI

// MARK: - Add Child

struct AddChildView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var familyService: FamilyService
    @EnvironmentObject var authService: AuthService

    @State private var name = ""
    @State private var hasBirthdate = false
    @State private var birthdateValue = Date()
    @State private var pin = ""

    @State private var error: String?
    @State private var isSaving = false

    var body: some View {
        NavigationView {
            Form {
                Section("Child") {
                    TextField("First name", text: $name)

                    Toggle("Set birthdate", isOn: $hasBirthdate)

                    if hasBirthdate {
                        DatePicker("Birthdate",
                                   selection: $birthdateValue,
                                   displayedComponents: .date)
                    }

                    TextField("4‑digit PIN (optional)", text: $pin)
                        .keyboardType(.numberPad)
                }

                if let error {
                    Text(error).foregroundColor(.red)
                }
            }
            .navigationTitle("Add Child")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Save") {
                        Task { await save() }
                    }
                    .disabled(isSaving || name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() async {
        isSaving = true; defer { isSaving = false }
        do {
            try await familyService.createChild(name: name.trimmingCharacters(in: .whitespaces),
                                               birthdate: hasBirthdate ? birthdateValue : nil,
                                               pin: pin.isEmpty ? nil : pin)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Add Chore

struct AddChoreView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var choreService: ChoreService
    @EnvironmentObject var familyService: FamilyService
    @EnvironmentObject var authService: AuthService

    @State private var title = ""
    @State private var description = ""
    @State private var points = 10
    @State private var requirePhoto = false

    // Simpler selection model
    @State private var selected: [String: Bool] = [:]

    @State private var error: String?
    @State private var isSaving = false

    var body: some View {
        NavigationView {
            Form {
                Section("Chore") {
                    TextField("Title", text: $title)
                    TextField("Description (optional)", text: $description)
                    Stepper("Points: \(points)", value: $points, in: 0...500, step: 5)
                    Toggle("Require photo proof", isOn: $requirePhoto)
                }

                Section("Assign to") {
                    if familyService.children.isEmpty {
                        Text("No children yet").foregroundColor(.secondary)
                    } else {
                        ForEach(familyService.children) { child in
                            let isOn = Binding(
                                get: { selected[child.id] ?? false },
                                set: { selected[child.id] = $0 }
                            )
                            Toggle(child.name, isOn: isOn)
                        }
                    }
                }

                if let error {
                    Text(error).foregroundColor(.red)
                }
            }
            .navigationTitle("Add Chore")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Save") {
                        Task { await save() }
                    }
                    .disabled(isSaving || title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if selected.isEmpty {
                    var map: [String: Bool] = [:]
                    for c in familyService.children { map[c.id] = false }
                    selected = map
                }
            }
        }
    }

    private func save() async {
        guard let parentId = authService.currentUser?.id,
              let familyId = authService.currentUser?.familyId ?? authService.currentUser?.id else { return }

        isSaving = true; defer { isSaving = false }

        let chore = Chore(
            id: UUID().uuidString,
            familyId: familyId,
            title: title.trimmingCharacters(in: .whitespaces),
            description: description.isEmpty ? nil : description,
            points: points,
            requirePhoto: requirePhoto,
            parentUserId: parentId,
            createdAt: Date()
        )

        do {
            let childIds = selected.filter { $0.value }.map { $0.key }
            try await choreService.createChore(chore, assignedTo: childIds)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Add Reward

struct AddRewardView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var rewardsService: RewardsService
    @EnvironmentObject var authService: AuthService

    @State private var name = ""
    @State private var cost = 50
    @State private var error: String?
    @State private var isSaving = false

    var body: some View {
        NavigationView {
            Form {
                TextField("Reward name", text: $name)
                Stepper("Cost: \(cost) points", value: $cost, in: 0...10000, step: 10)
                if let error { Text(error).foregroundColor(.red) }
            }
            .navigationTitle("Add Reward")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Save") {
                        Task { await save() }
                    }
                    .disabled(isSaving || name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() async {
        guard let familyId = authService.currentUser?.familyId ?? authService.currentUser?.id else { return }
        isSaving = true; defer { isSaving = false }
        do {
            let reward = Reward(
                id: UUID().uuidString,
                familyId: familyId,
                name: name.trimmingCharacters(in: .whitespaces),
                costPoints: cost,
                createdAt: Date()
            )
            try await rewardsService.createReward(reward)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Approvals

struct ApprovalsView: View {
    @EnvironmentObject var choreService: ChoreService
    @State private var error: String?

    var body: some View {
        List {
            if choreService.pendingApprovals.isEmpty {
                Text("Nothing to approve right now").foregroundColor(.secondary)
            } else {
                ForEach(choreService.pendingApprovals) { c in
                    ApprovalRow(completion: c) { action in
                        Task {
                            do {
                                switch action {
                                case .approve: try await choreService.approveCompletion(c)
                                case .reject:  try await choreService.rejectCompletion(c)
                                }
                            } catch { self.error = error.localizedDescription }
                        }
                    }
                }
            }

            if let error { Text(error).foregroundColor(.red) }
        }
        .navigationTitle("Approvals")
    }
}

private enum ApprovalAction { case approve, reject }

private struct ApprovalRow: View {
    let completion: ChoreCompletion
    let onAction: (ApprovalAction) -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Completion \(completion.id.prefix(6))…")
                    .font(.headline)
                Text("Status: \(completion.status.rawValue)")
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            HStack(spacing: 8) {
                Button("Approve") { onAction(.approve) }
                    .buttonStyle(.borderedProminent)
                Button("Reject")  { onAction(.reject)  }
                    .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 6)
    }
}
