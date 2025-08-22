import SwiftUI

struct AddChildView: View {
    @EnvironmentObject var familyService: FamilyService
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var birthdate = Date()
    @State private var pin = ""
    @State private var confirmPin = ""
    @State private var error: String?
    @State private var isLoading = false
    
    private var isFormValid: Bool {
        !name.isEmpty && 
        pin.count == 4 && 
        pin == confirmPin &&
        pin.allSatisfy(\.isNumber)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Child Information") {
                    TextField("Child's name", text: $name)
                    
                    DatePicker(
                        "Birthdate",
                        selection: $birthdate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                }
                
                Section("Security PIN") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create a 4-digit PIN for your child to sign in")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        SecureField("4-digit PIN", text: $pin)
                            .keyboardType(.numberPad)
                        
                        SecureField("Confirm PIN", text: $confirmPin)
                            .keyboardType(.numberPad)
                        
                        if !pin.isEmpty && pin.count != 4 {
                            Text("PIN must be exactly 4 digits")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        if !pin.isEmpty && !confirmPin.isEmpty && pin != confirmPin {
                            Text("PINs don't match")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section("Tips") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Choose a PIN your child can remember", systemImage: "lightbulb")
                        Label("Avoid obvious numbers like 1234", systemImage: "exclamationmark.triangle")
                        Label("Your child will use this PIN to sign in", systemImage: "person.badge.key")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                if let error {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("Add Child")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await saveChild() }
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
    
    private func saveChild() async {
        isLoading = true
        error = nil
        
        do {
            try await familyService.createChild(
                name: name,
                birthdate: birthdate,
                pin: pin
            )
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
}