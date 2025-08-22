//
//  AuthenticationView.swift
//  AllowanceAlleyNextgen
//
//  Created by Paul Marshall on 8/22/25.
//
import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authService: AuthService
    
    @State private var email = ""
    @State private var password = ""
    @State private var familyName = "My Family"
    @State private var isSignup = true
    @State private var error: String?
    
    var body: some View {
        VStack(spacing: 16) {
            Text(isSignup ? "Sign Up" : "Sign In").font(.largeTitle).bold()
            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
            SecureField("Password", text: $password).textFieldStyle(.roundedBorder)
            if isSignup { TextField("Family name", text: $familyName).textFieldStyle(.roundedBorder) }
            if let error { Text(error).foregroundColor(.red).font(.footnote) }
            Button(isSignup ? "Create account" : "Sign in") {
                Task {
                    do {
                        if isSignup { try await authService.signUp(email: email, password: password, familyName: familyName) }
                        else { try await authService.signIn(email: email, password: password) }
                    } catch { self.error = error.localizedDescription }
                }
            }.buttonStyle(.borderedProminent)
            Button(isSignup ? "Have an account? Sign in" : "Need an account? Sign up") { isSignup.toggle() }.font(.footnote)
        }
        .padding()
    }
}

