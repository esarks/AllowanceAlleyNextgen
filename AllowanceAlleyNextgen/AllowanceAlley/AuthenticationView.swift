// =============================================================================
// FILE: AuthenticationView.swift (Simple Login/Signup)
// =============================================================================

import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var auth: AuthService
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSignUp = false
    @State private var error: String?
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Allowance Alley").font(.largeTitle).bold()
            
            // Debug info
            VStack(alignment: .leading, spacing: 4) {
                Text("Debug Info:").font(.caption).bold()
                Text("Auth Status: \(auth.isAuthenticated ? "Authenticated" : "Not Authenticated")")
                    .font(.caption2)
                Text("Current User: \(auth.currentUser?.email ?? "None")")
                    .font(.caption2)
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .textFieldStyle(.roundedBorder)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                
                Toggle("Sign Up (new user)", isOn: $isSignUp)
            }
            .frame(maxWidth: 420)

            Button(isLoading ? "Please wait..." : (isSignUp ? "Sign Up" : "Sign In")) {
                Task { await authenticate() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(email.isEmpty || password.isEmpty || isLoading)
            
            // Demo Mode Button for immediate testing
            Button("Demo Mode (Skip Auth)") {
                createDemoUser()
            }
            .buttonStyle(.bordered)
            .foregroundColor(.orange)
            
            if let error {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
    
    private func authenticate() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            if isSignUp {
                try await auth.signUp(email: email, password: password)
            } else {
                try await auth.signIn(email: email, password: password)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    private func createDemoUser() {
        // Create a demo user for testing navigation
        auth.isAuthenticated = true
        auth.currentUser = AppUser(
            id: "demo-user-123",
            email: "demo@example.com",
            role: .parent,
            familyId: "demo-family-456"
        )
    }
}
