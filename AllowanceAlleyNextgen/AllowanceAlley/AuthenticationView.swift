import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authService: AuthService
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var familyName = ""
    @State private var error: String?
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    Text("Allowance Alley")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Manage chores and rewards for your family")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Form
                VStack(spacing: 16) {
                    // Toggle between Sign In / Sign Up
                    Picker("Mode", selection: $isSignUp) {
                        Text("Sign In").tag(false)
                        Text("Sign Up").tag(true)
                    }
                    .pickerStyle(.segmented)
                    
                    // Email field
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    // Password field
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                    
                    // Family name for sign up
                    if isSignUp {
                        TextField("Family Name", text: $familyName)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Error message
                    if let error {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                    
                    // Submit button
                    Button {
                        Task { await handleAuth() }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(isSignUp ? "Create Account" : "Sign In")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading || email.isEmpty || password.isEmpty || (isSignUp && familyName.isEmpty))
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Child login option
                VStack(spacing: 16) {
                    Divider()
                    
                    Text("Child? Ask a parent to help you sign in")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    NavigationLink("Child Sign In") {
                        ChildSignInView()
                    }
                    .font(.footnote)
                }
                .padding(.bottom, 32)
            }
            .padding()
        }
    }
    
    private func handleAuth() async {
        isLoading = true
        error = nil
        
        do {
            if isSignUp {
                try await authService.signUp(email: email, password: password, familyName: familyName)
            } else {
                try await authService.signIn(email: email, password: password)
            }
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
}

struct ChildSignInView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @State private var pin = ""
    @State private var error: String?
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Child Sign In")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Enter your 4-digit PIN")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextField("PIN", text: $pin)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.title)
            
            if let error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.footnote)
            }
            
            Button("Sign In") {
                Task {
                    do {
                        try await authService.signInChild(childId: "demo-child", pin: pin)
                        dismiss()
                    } catch {
                        self.error = error.localizedDescription
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(pin.count != 4)
            
            Spacer()
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
    }
}