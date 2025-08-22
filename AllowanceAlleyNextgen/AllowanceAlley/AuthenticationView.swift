
import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var familyService: FamilyService

    @State private var email = ""
    @State private var password = ""
    @State private var familyName = "My Family"
    @State private var selectedChild: Child?
    @State private var childPin = ""
    @State private var isSignup = true
    @State private var showingChildLogin = false
    @State private var error: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Allowance Alley")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)

                    Text("Chores, rewards, and family fun!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)

                Spacer()

                // Login Type Selector
                HStack(spacing: 0) {
                    Button("Parent") {
                        showingChildLogin = false
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(showingChildLogin ? Color.clear : Color.blue)
                    .foregroundColor(showingChildLogin ? .blue : .white)

                    Button("Child") {
                        showingChildLogin = true
                        Task {
                            try? await familyService.loadFamily()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(showingChildLogin ? Color.blue : Color.clear)
                    .foregroundColor(showingChildLogin ? .white : .blue)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue, lineWidth: 2)
                )
                .cornerRadius(8)

                // Login Forms
                if showingChildLogin {
                    ChildLoginForm(
                        children: familyService.children,
                        selectedChild: $selectedChild,
                        childPin: $childPin,
                        error: $error
                    )
                } else {
                    ParentLoginForm(
                        email: $email,
                        password: $password,
                        familyName: $familyName,
                        isSignup: $isSignup,
                        error: $error
                    )
                }

                Spacer()
            }
            .padding()
        }
    }
}

struct ParentLoginForm: View {
    @EnvironmentObject var authService: AuthService
    @Binding var email: String
    @Binding var password: String
    @Binding var familyName: String
    @Binding var isSignup: Bool
    @Binding var error: String?

    var body: some View {
        VStack(spacing: 16) {
            Text(isSignup ? "Create Family Account" : "Sign In")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)

                if isSignup {
                    TextField("Family name", text: $familyName)
                        .textFieldStyle(.roundedBorder)
                }
            }

            if let error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
            }

            Button(isSignup ? "Create Account" : "Sign In") {
                Task {
                    do {
                        if isSignup {
                            try await authService.signUp(email: email, password: password, familyName: familyName)
                        } else {
                            try await authService.signIn(email: email, password: password)
                        }
                    } catch {
                        self.error = error.localizedDescription
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)

            Button(isSignup ? "Already have an account? Sign in" : "Need an account? Sign up") {
                isSignup.toggle()
                error = nil
            }
            .font(.footnote)
            .foregroundColor(.blue)
        }
    }
}

struct ChildLoginForm: View {
    @EnvironmentObject var authService: AuthService
    let children: [Child]
    @Binding var selectedChild: Child?
    @Binding var childPin: String
    @Binding var error: String?

    var body: some View {
        VStack(spacing: 16) {
            Text("Child Login")
                .font(.title2)
                .fontWeight(.semibold)

            if children.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "person.2.slash")
                        .font(.title)
                        .foregroundColor(.secondary)

                    Text("No children found")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Ask your parent to add you to the family first")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                VStack(spacing: 12) {
                    Text("Select your name:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(children) { child in
                            ChildSelectionCard(
                                child: child,
                                isSelected: selectedChild?.id == child.id
                            ) {
                                selectedChild = child
                            }
                        }
                    }

                    if selectedChild != nil {
                        SecureField("Enter your PIN", text: $childPin)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                    }
                }

                if let error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                }

                Button("Sign In") {
                    guard let child = selectedChild else {
                        error = "Please select your name"
                        return
                    }

                    Task {
                        do {
                            try await authService.signInChild(childId: child.id, pin: childPin)
                        } catch {
                            self.error = error.localizedDescription
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(selectedChild == nil || childPin.isEmpty)
            }
        }
    }
}

struct ChildSelectionCard: View {
    let child: Child
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Circle()
                    .fill(isSelected ? Color.blue : Color.gray)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(child.name.prefix(1)))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )

                Text(child.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .blue : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                    .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}
