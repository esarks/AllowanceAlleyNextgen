
import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var auth: AuthService
    @State private var email: String = ""

    var body: some View {
        VStack(spacing: 24) {
            Text("Allowance Alley").font(.largeTitle).bold()
            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 420)

            Button("Send 6-digit code") {
                Task { try? await auth.sendCode(to: email) }
            }
            .buttonStyle(.borderedProminent)
            .disabled(email.isEmpty)
        }
        .padding()
    }
}
