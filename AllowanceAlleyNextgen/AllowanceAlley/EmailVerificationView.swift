
import SwiftUI

struct EmailVerificationView: View {
    @EnvironmentObject var auth: AuthService
    @State private var code: String = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Check your email").font(.title2).bold()
            Text("Enter the 6-digit code we sent to \(auth.pendingVerificationEmail ?? "")")
                .multilineTextAlignment(.center)

            TextField("123456", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 200)

            Button("Verify") {
                Task { try? await auth.verifyCode(code) }
            }
            .buttonStyle(.borderedProminent)
            .disabled(code.count < 6)

            Button("Resend code") {
                if let email = auth.pendingVerificationEmail {
                    Task { try? await auth.sendCode(to: email) }
                }
            }.buttonStyle(.bordered)
        }
        .padding()
    }
}
