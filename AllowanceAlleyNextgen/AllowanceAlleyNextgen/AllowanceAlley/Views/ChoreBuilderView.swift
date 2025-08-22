//
//  ChoreBuilderView.swift
//  AllowanceAlley
//

import SwiftUI

struct ChoreBuilderView: View {
    @EnvironmentObject var choreService: ChoreService
    @EnvironmentObject var familyService: FamilyService
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var points = ""
    @State private var valueCents = ""
    @State private var requiresPhoto = false
    @State private var recurrenceRule = RecurrenceRule.none
    @State private var selectedChildren: Set<String> = []
    @State private var dueDate = Date().adding(days: 1)
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Chore Details") {
                    TextField("Title", text: $title)
                        .textContentType(.none)
                    
                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    HStack {
                        TextField("Points", text: $points)
                            .keyboardType(.numberPad)
                        
                        Divider()
                        
                        TextField("Value ¢ (Optional)", text: $valueCents)
                            .keyboardType(.numberPad)
                    }
                }
                
                Section("Settings") {
                    Picker("Recurrence", selection: $recurrenceRule) {
                        ForEach(RecurrenceRule.allCases, id: \.self) { rule in
                            Text(rule.displayName).tag(rule)
                        }
                    }
                    
                    if recurrenceRule == .none {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                    
                    Toggle("Requires Photo", isOn: $requiresPhoto)
                }
                
                Section("Assign To") {
                    if familyService.children.isEmpty {
                        Text("No children added yet")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(familyService.children) { child in
                            HStack {
                                Image(systemName: selectedChildren.contains(child.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedChildren.contains(child.id) ? .blue : .gray)
                                
                                Text(child.displayName)
                                
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedChildren.contains(child.id) {
                                    selectedChildren.remove(child.id)
                                } else {
                                    selectedChildren.insert(child.id)
                                }
                            }
                            .accessibilityLabel("Assign to \(child.displayName)")
                            .accessibilityValue(selectedChildren.contains(child.id) ? "Selected" : "Not selected")
                        }
                    }
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Create Chore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createChore()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
        .onAppear {
            // Pre-select all children if none are selected
            if selectedChildren.isEmpty {
                selectedChildren = Set(familyService.children.map { $0.id })
            }
        }
    }
    
    private var isFormValid: Bool {
        !title.isEmpty && !points.isEmpty && !selectedChildren.isEmpty
    }
    
    private func createChore() {
        guard let pointsValue = Int(points),
              let family = familyService.currentFamily,
              let currentUser = authService.currentUser else {
            errorMessage = "Invalid input"
            return
        }
        
        let valueCentsInt = Int(valueCents) ?? 0
        
        let chore = Chore(
            familyId: family.id,
            title: title,
            choreDescription: description.isEmpty ? nil : description, // << fixed key
            points: pointsValue,
            valueCents: valueCentsInt > 0 ? valueCentsInt : nil,
            requiresPhoto: requiresPhoto,
            recurrenceRule: recurrenceRule,
            createdBy: currentUser.id
        )
        
        Task {
            do {
                try await choreService.createChore(chore, assignedTo: Array(selectedChildren))
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
