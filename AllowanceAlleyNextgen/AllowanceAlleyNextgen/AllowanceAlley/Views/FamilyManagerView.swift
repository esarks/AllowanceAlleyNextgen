//
//  FamilyManagerView.swift
//  AllowanceAlley
//

import SwiftUI

struct FamilyManagerView: View {
    @EnvironmentObject var familyService: FamilyService
    @EnvironmentObject var authService: AuthService
    
    @State private var showingAddChild = false
    @State private var editingChild: AppUser?
    @State private var showingDeleteConfirmation = false
    @State private var childToDelete: AppUser?
    
    var body: some View {
        NavigationView {
            List {
                // Family Info Section
                Section("Family") {
                    if let family = familyService.currentFamily {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(family.name)
                                .font(.headline)
                            
                            Text("Created: \(family.createdAt, style: .date)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(familyService.children.count) children")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // Children Section
                Section("Children") {
                    ForEach(familyService.children) { child in
                        ChildRowView(
                            child: child,
                            onEdit: { editingChild = child },
                            onDelete: { 
                                childToDelete = child
                                showingDeleteConfirmation = true
                            }
                        )
                    }
                    
                    Button(action: { showingAddChild = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                            Text("Add Child")
                                .foregroundColor(.blue)
                        }
                    }
                    .accessibilityLabel("Add new child")
                }
            }
            .navigationTitle("Family Manager")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Handle done if needed
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddChild) {
            AddChildView()
        }
        .sheet(item: $editingChild) { child in
            EditChildView(child: child)
        }
        .alert("Delete Child", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let child = childToDelete {
                    deleteChild(child)
                }
            }
        } message: {
            Text("Are you sure you want to delete this child? This action cannot be undone.")
        }
        .onAppear {
            Task {
                try await familyService.loadFamily()
            }
        }
    }
    
    private func deleteChild(_ child: AppUser) {
        Task {
            try await familyService.deleteChild(child)
        }
    }
}

struct ChildRowView: View {
    let child: AppUser
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            // Avatar
            Circle()
                .fill(Color.blue)
                .frame(width: 50, height: 50)
                .overlay(
                    AsyncImageView(
                        url: child.avatarURL ?? "",
                        placeholder: Image(systemName: "person.fill")
                    )
                    .clipShape(Circle())
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(child.displayName)
                    .font(.headline)
                
                HStack {
                    Text("Child")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(4)
                    
                    if child.childPIN != nil {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
            
            Menu {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
                
                Button(action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .accessibilityLabel("Child options")
        }
        .padding(.vertical, 4)
    }
}

struct AddChildView: View {
    @EnvironmentObject var familyService: FamilyService
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var pin = ""
    @State private var confirmPin = ""
    @State private var errorMessage = ""
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Child Information") {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                    
                    SecureField("PIN (4 digits)", text: $pin)
                        .keyboardType(.numberPad)
                        .onChange(of: pin) { newValue in
                            if newValue.count > 4 {
                                pin = String(newValue.prefix(4))
                            }
                        }
                    
                    SecureField("Confirm PIN", text: $confirmPin)
                        .keyboardType(.numberPad)
                        .onChange(of: confirmPin) { newValue in
                            if newValue.count > 4 {
                                confirmPin = String(newValue.prefix(4))
                            }
                        }
                }
                
                Section("Avatar") {
                    HStack {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.title)
                                        .foregroundColor(.gray)
                                )
                        }
                        
                        Button("Choose Photo") {
                            showingImagePicker = true
                        }
                        .foregroundColor(.blue)
                        
                        Spacer()
                    }
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Add Child")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChild()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && pin.count == 4 && pin == confirmPin
    }
    
    private func saveChild() {
        guard isFormValid else {
            errorMessage = "Please fill in all fields correctly"
            return
        }
        
        Task {
            do {
                try await familyService.addChild(name: name, pin: pin)
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

struct EditChildView: View {
    let child: AppUser
    @EnvironmentObject var familyService: FamilyService
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String
    @State private var pin = ""
    @State private var confirmPin = ""
    @State private var errorMessage = ""
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    
    init(child: AppUser) {
        self.child = child
        self._name = State(initialValue: child.displayName)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Child Information") {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                    
                    SecureField("New PIN (4 digits)", text: $pin)
                        .keyboardType(.numberPad)
                        .onChange(of: pin) { newValue in
                            if newValue.count > 4 {
                                pin = String(newValue.prefix(4))
                            }
                        }
                    
                    if !pin.isEmpty {
                        SecureField("Confirm PIN", text: $confirmPin)
                            .keyboardType(.numberPad)
                            .onChange(of: confirmPin) { newValue in
                                if newValue.count > 4 {
                                    confirmPin = String(newValue.prefix(4))
                                }
                            }
                    }
                }
                
                Section("Avatar") {
                    HStack {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } else {
                            AsyncImageView(
                                url: child.avatarURL ?? "",
                                placeholder: Image(systemName: "person.fill")
                            )
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                        }
                        
                        Button("Change Photo") {
                            showingImagePicker = true
                        }
                        .foregroundColor(.blue)
                        
                        Spacer()
                    }
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Edit Child")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
        }
    }
    
    private var isFormValid: Bool {
        let nameValid = !name.isEmpty
        let pinValid = pin.isEmpty || (pin.count == 4 && pin == confirmPin)
        return nameValid && pinValid
    }
    
    private func saveChanges() {
        guard isFormValid else {
            errorMessage = "Please fill in all fields correctly"
            return
        }
        
        Task {
            do {
                var updatedChild = child
                updatedChild.displayName = name
                if !pin.isEmpty {
                    updatedChild.childPIN = pin
                }
                updatedChild.updatedAt = Date()
                
                try await familyService.updateChild(updatedChild)
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