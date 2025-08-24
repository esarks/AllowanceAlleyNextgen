import SwiftUI

// MARK: - Add Child

struct AddChildView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService

    @State private var name = ""
    @State private var hasBirthdate = false
    @State private var birthdateValue = Date()
    @State private var pin = ""               // UI only; not saved

    @State private var error: String?
    @State private var isSaving = false

    var body: some View {
        NavigationView {
            Form {
                Section("Child") {
                    TextField("First name", text: $name)
                    Toggle("Set birthdate", isOn: $hasBirthdate)
                    if hasBirthdate {
                        DatePicker(
                            "Birthdate",
                            selection: $birthdateValue,
                            displayedComponents: .date
                        )
                    }
                    TextField("4-digit PIN (optional)", text: $pin)
                        .keyboardType(.numberPad)
                }

                if let error { Text(error).foregroundColor(.red) }
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
        guard let familyId = authService.currentUser?.familyId else {
            self.error = "Missing family context"; return
        }
        do {
            _ = try await DatabaseAPI.shared.createChildMember(
                familyId: familyId,
                childName: name.trimmingCharacters(in: .whitespaces),
                age: nil
            )
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

// Small wrapper so the Toggle binding is trivial (helps the type-checker)
private struct ChildSelectRow: View {
    let child: SelectableChild
    @Binding var selected: Set<String>

    var isOn: Bool { selected.contains(child.id) }

    var body: some View {
        Toggle(child.name, isOn: Binding(
            get: { isOn },
            set: { on in
                if on { selected.insert(child.id) }
                else { selected.remove(child.id) }
            }
        ))
    }
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
                    if isLoadingKids { ProgressView() }
                    else if children.isEmpty {
                        Text("No children yet").foregroundColor(.secondary)
                    } else {
                        ForEach(children) { child in
                            ChildSelectRow(child: child, selected: $selected)
                        }
                    }
                }

                if let error { Text(error).foregroundColor(.red) }
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
        isLoadingKids = true; defer { isLoadingKids = false }
        do {
            let members = try await DatabaseAPI.shared.listFamilyMembers(
                familyId: familyId,
                role: .child
            )
            self.children = members.map {
                SelectableChild(id: $0.id, name: $0.childName ?? "Child \($0.id.prefix(4))")
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func save() async {
        guard let familyId = authService.currentUser?.familyId,
              let parentId = authService.currentUser?.id else {
            self.error = "Missing family or user context"; return
        }

        if selected.isEmpty {
            self.error = "Select at least one child."
            return
        }

        isSaving = true; defer { isSaving = false }

        do {
            let chore = try await DatabaseAPI.shared.createChore(
                familyId: familyId,
                title: title.trimmingCharacters(in: .whitespaces),
                description: description.isEmpty ? nil : description,
                points: points,
                requirePhoto: requirePhoto,
                recurrence: nil,
                parentUserId: parentId
            )
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
        isLoading = true; defer { isLoading = false }
        do {
            let all = try await DatabaseAPI.shared.fetchCompletionsForFamily(familyId: familyId)
            self.items = all.filter { $0.status == .pending }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func act(on c: ChoreCompletion, action: ApprovalAction) async {
        guard let reviewer = authService.currentUser?.id else { return }
        do {
            let status: CompletionStatus = (action == .approve) ? .approved : .rejected
            _ = try await DatabaseAPI.shared.reviewCompletion(
                id: c.id,
                status: status,
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
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            HStack(spacing: 8) {
                Button("Approve") { onAction(.approve) }
                    .buttonStyle(.borderedProminent)
                Button("Reject") { onAction(.reject) }
                    .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 6)
    }
}
