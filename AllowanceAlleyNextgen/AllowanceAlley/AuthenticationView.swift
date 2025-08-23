import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authService: AuthService

    @State private var email = ""
    @State private var password = ""
    @State private var familyName = ""

    @State private var signinError: String?
    @State private var signupError: String?
    @State private var working = false

    var body: some View {
        NavigationView {
            Form {
                Section("Account") {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                }

                Section("Family (optional for sign up)") {
                    TextField("Family Name", text: $familyName)
                }

                if let signinError { Text(signinError).foregroundColor(.red) }
                if let signupError { Text(signupError).foregroundColor(.red) }

                Section {
                    Button(working ? "Signing In…" : "Sign In") {
                        Task { await signIn() }
                    }
                    .disabled(working || email.isEmpty || password.isEmpty)

                    Button(working ? "Creating…" : "Sign Up") {
                        Task { await signUp() }
                    }
                    .disabled(working || email.isEmpty || password.isEmpty)
                }
            }
            .navigationTitle("Welcome")
        }
    }

    private func signIn() async {
        working = true; defer { working = false }
        signinError = nil
        do {
            try await authService.signIn(email: email.trimmingCharacters(in: .whitespaces),
                                         password: password)
        } catch {
            signinError = error.localizedDescription
        }
    }

    private func signUp() async {
        working = true; defer { working = false }
        signupError = nil
        do {
            try await authService.signUp(email: email.trimmingCharacters(in: .whitespaces),
                                         password: password,
                                         familyName: familyName.trimmingCharacters(in: .whitespaces))
        } catch {
            signupError = error.localizedDescription
        }
    }
}
