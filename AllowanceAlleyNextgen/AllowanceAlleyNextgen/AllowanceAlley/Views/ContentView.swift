//
//  ContentView.swift
//  AllowanceAlley
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var familyService: FamilyService
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                // User is authenticated - show appropriate main view
                if let user = authService.currentUser {
                    switch user.role {
                    case .parent:
                        DashboardView()
                    case .child:
                        TodayView(childId: user.id)
                    }
                } else {
                    // Edge case: authenticated but no user data
                    Text("Loading user data...")
                        .onAppear {
                            Task {
                                try await authService.signOut()
                            }
                        }
                }
            } else {
                // User is not authenticated - show login/signup flow
                AuthenticationView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authService.isAuthenticated)
    }
}

struct AuthenticationView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var familyService: FamilyService
    
    @State private var isShowingSignUp = false
    @State private var isShowingChildLogin = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // App Logo/Title
                VStack(spacing: 16) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Allowance Alley")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Manage chores and rewards for your family")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Authentication Options
                VStack(spacing: 16) {
                    // Parent Sign In/Up
                    VStack(spacing: 12) {
                        Button(action: { isShowingSignUp = true }) {
                            HStack {
                                Image(systemName: "person.2.fill")
                                Text("Create Family Account")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            // For demo purposes, sign in directly
                            Task {
                                try await authService.signIn(email: "parent@demo.com", password: "demo")
                            }
                        }) {
                            HStack {
                                Image(systemName: "person.fill")
                                Text("Parent Sign In")
                            }
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                        }
                    }
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                        
                        Text("or")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                    }
                    
                    // Child Sign In
                    Button(action: { isShowingChildLogin = true }) {
                        HStack {
                            Image(systemName: "person.crop.circle.fill")
                            Text("I'm a Kid")
                        }
                        .font(.headline)
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green, lineWidth: 2)
                        )
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Demo Info
                VStack(spacing: 8) {
                    Text("Demo Mode")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Text("This is a demo version with simulated data")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $isShowingSignUp) {
            ParentSignUpView()
        }
        .sheet(isPresented: $isShowingChildLogin) {
            ChildLoginView()
        }
    }
}

struct ParentSignUpView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var familyName = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Family Information") {
                    TextField("Family Name", text: $familyName)
                        .textContentType(.organizationName)
                }
                
                Section("Parent Account") {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button(action: signUp) {
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Create Account")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
            .navigationTitle("Create Family")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && !familyName.isEmpty &&
        password == confirmPassword && password.count >= 6
    }
    
    private func signUp() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                try await authService.signUp(email: email, password: password, familyName: familyName)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

struct ChildLoginView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var familyService: FamilyService
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedChild: AppUser?
    @State private var enteredPIN = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("Choose Your Profile")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Select your name and enter your PIN")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Demo children (since we don't have real family data)
                VStack(spacing: 16) {
                    Text("Demo Children")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    ForEach(demoChildren, id: \.id) { child in
                        Button(action: {
                            selectedChild = child
                            enteredPIN = ""
                        }) {
                            HStack {
                                Circle()
                                    .fill(selectedChild?.id == child.id ? Color.green : Color.gray.opacity(0.3))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Text(String(child.displayName.prefix(2)).uppercased())
                                            .font(.headline)
                                            .foregroundColor(selectedChild?.id == child.id ? .white : .primary)
                                    )
                                
                                Text(child.displayName)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if selectedChild?.id == child.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                            .padding()
                            .background(selectedChild?.id == child.id ? Color.green.opacity(0.1) : Color.gray.opacity(0.05))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal)
                
                // PIN Entry
                if selectedChild != nil {
                    VStack(spacing: 16) {
                        Text("Enter your PIN")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            ForEach(0..<4, id: \.self) { index in
                                Circle()
                                    .fill(index < enteredPIN.count ? Color.green : Color.gray.opacity(0.3))
                                    .frame(width: 20, height: 20)
                            }
                        }
                        
                        // PIN Pad
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                            ForEach(1...9, id: \.self) { number in
                                Button(action: {
                                    if enteredPIN.count < 4 {
                                        enteredPIN += String(number)
                                    }
                                }) {
                                    Text(String(number))
                                        .font(.title)
                                        .fontWeight(.semibold)
                                        .frame(width: 60, height: 60)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(30)
                                }
                            }
                            
                            // Empty space
                            Color.clear
                                .frame(width: 60, height: 60)
                            
                            // Zero
                            Button(action: {
                                if enteredPIN.count < 4 {
                                    enteredPIN += "0"
                                }
                            }) {
                                Text("0")
                                    .font(.title)
                                    .fontWeight(.semibold)
                                    .frame(width: 60, height: 60)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(30)
                            }
                            
                            // Delete
                            Button(action: {
                                if !enteredPIN.isEmpty {
                                    enteredPIN.removeLast()
                                }
                            }) {
                                Image(systemName: "delete.left")
                                    .font(.title2)
                                    .frame(width: 60, height: 60)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(30)
                            }
                        }
                        .padding(.horizontal)
                        
                        if enteredPIN.count == 4 {
                            Button(action: signInChild) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Sign In")
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.green)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .disabled(isLoading)
                        }
                    }
                }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Kid Login")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var demoChildren: [AppUser] {
        [
            AppUser(role: .child, childPIN: "1234", displayName: "Emma"),
            AppUser(role: .child, childPIN: "5678", displayName: "Jake"),
            AppUser(role: .child, childPIN: "9999", displayName: "Sophie")
        ]
    }
    
    private func signInChild() {
        guard let child = selectedChild else { return }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                try await authService.signInChild(childId: child.id, pin: enteredPIN)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Incorrect PIN. Try again."
                    enteredPIN = ""
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService.shared)
        .environmentObject(FamilyService.shared)
        .environmentObject(ChoreService.shared)
        .environmentObject(RewardsService.shared)
        .environmentObject(NotificationsService.shared)
        .environmentObject(ImageStore.shared)
}
