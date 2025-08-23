import SwiftUI

// MARK: - Add Child

struct AddChildView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService

    @State private var name = ""
    @State private var hasBirthdate = false
    @State private var birthdateValue = Date()
    @State private var pin = ""               // kept for UI; not sent to DB

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

                    TextField("4-digit PIN (optional)", text: $pin)
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
        guard let familyId = authService.currentUser?.familyId,
              let parentId = authService.currentUser?.id else {
            self.error = "Missing family or user context"
            return
        }

        do {
            // Prefer the canonical family_members entry for a child
            _ = try await DatabaseAPI.shared.createChildMember(
                familyId: familyId,
                childName: name.trimmingCharacters(in: .whitespaces),
                age: nil
            )

            // Optional: also create a child profile record if you’re using that table
            // _ = try await DatabaseAPI.shared.createChildProfile(
            //     parentUserId: parentId,
            //     name: name.trimmingCharacters(in: .whitespaces),
            //     birthdate: hasBirthdate ? birthdateValue : nil,
            //     avatarURL: nil
            // )

            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Add Chore

private struct SelectableChild: Identifiable, Hashable {
    let id: String
    let name: String
}

struct AddChoreView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService

    @State private var title = ""
    @State private var description = ""
    @State private var points = 10
    @State private var requirePhoto = false

    @State private var children: [SelectableChild] = []
    @State private var selected: Set<String> = []

    @State private var error: String?
    @State private var isSaving = false
    @State private var isLoadingKids = false

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
                    if isLoadingKids {
                        ProgressView().progressViewStyle(.circular)
                    } else if children.isEmpty {
                        Text("No children yet").foregroundColor(.secondary)
                    } else {
                        ForEach(children) { child in
                            Toggle(isOn: Binding(
                                get: { selected.contains(child.id) },
                                set: { isOn in
                                    if isOn { selected.insert(child.id) }
                                    else { selected.remove(child.id) }
                                })
                            ) {
                                Text(child.name)
                            }
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
            .task { await loadChildren() }
        }
    }

    private func loadChildren() async {
        guard let familyId = authService.currentUser?.familyId else { return }
        isLoadingKids = true
        defer { isLoadingKids = false }
        do {
            // Pull family members with child role
            let members = try await DatabaseAPI.shared.listFamilyMembers(
                familyId: familyId,
                role: .child
            )
            self.children = members.map {
                // Try common name keys; fall back to id
                SelectableChild(id: $0.id, name: ($0.name ?? $0.childName ?? "Child \($0.id.prefix(4))"))
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func save() async {
        guard let familyId = authService.currentUser?.familyId,
              let parentId = authService.currentUser?.id else {
            self.error = "Missing family or user context"
            return
        }

        isSaving = true; defer { isSaving = false }

        do {
            // Create chore
            let chore = try await DatabaseAPI.shared.createChore(
                familyId: familyId,
                title: title.trimmingCharacters(in: .whitespaces),
                description: description.isEmpty ? nil : description,
                points: points,
                requirePhoto: requirePhoto,
                recurrence: nil,
                parentUserId: parentId
            )

            // Assign to selected members
            for childId in selected {
                _ = try await DatabaseAPI.shared.assignChore(
                    choreId: chore.id,
                    memberId: childId,
                    due: nil
                )
            }

            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Add Reward

struct AddRewardView: View {
    @Environment(\.dismiss) private var dismiss
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
        guard let familyId = authService.currentUser?.familyId else { return }
        isSaving = true; defer { isSaving = false }
        do {
            _ = try await DatabaseAPI.shared.createReward(
                familyId: familyId,
                name: name.trimmingCharacters(in: .whitespaces),
                costPoints: cost
            )
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Approvals

struct ApprovalsView: View {
    @EnvironmentObject var authService: AuthService

    @State private var items: [ChoreCompletion] = []
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        List {
            if let error { Text(error).foregroundColor(.red) }

            if items.isEmpty && !isLoading {
                Text("Nothing to approve right now").foregroundColor(.secondary)
            }

            ForEach(items) { c in
                ApprovalRow(completion: c) { action in
                    Task { await act(on: c, action: action) }
                }
            }
        }
        .navigationTitle("Approvals")
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        guard let familyId = authService.currentUser?.familyId else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let all = try await DatabaseAPI.shared.fetchCompletionsForFamily(familyId: familyId)
            // Keep only pending
            self.items = all.filter { $0.status == .pending }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func act(on c: ChoreCompletion, action: ApprovalAction) async {
        guard let reviewer = authService.currentUser?.id else { return }
        do {
            let newStatus: CompletionStatus = (action == .approve) ? .approved : .rejected
            _ = try await DatabaseAPI.shared.reviewCompletion(
                id: c.id,
                status: newStatus,
                reviewedBy: reviewer
            )
            await load()
        } catch {
            self.error = error.localizedDescription
        }
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
