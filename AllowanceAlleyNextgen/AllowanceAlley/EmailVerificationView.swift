import SwiftUI

struct EmailVerificationView: View {
    @EnvironmentObject var authService: AuthService

    @State private var code: String = ""
    @State private var isWorking = false
    @State private var error: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Enter Verification Code")
                    .font(.title3)
                    .fontWeight(.semibold)

                if let email = authService.pendingVerificationEmail {
                    Text("We emailed a 6‑digit code to:")
                        .foregroundColor(.secondary)
                    Text(email)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                TextField("6‑digit code", text: $code)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    // iOS 17+ onChange (two‑arg or zero‑arg). Use zero‑arg here.
                    .onChange(of: code) {
                        code = String(code.prefix(6))
                    }

                if let error {
                    Text(error).foregroundColor(.red)
                }

                Button(isWorking ? "Verifying…" : "Verify") {
                    Task { await verify() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isWorking || code.count != 6)

                Button("Resend Code") {
                    Task { await resend() }
                }
                .disabled(isWorking)
                .padding(.top, 4)

                Spacer()
            }
            .padding()
            .navigationTitle("Verify Email")
        }
    }

    private func verify() async {
        isWorking = true; defer { isWorking = false }
        do {
            try await authService.verifyCode(code)
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func resend() async {
        isWorking = true; defer { isWorking = false }
        do {
            try await authService.resendVerificationCode()
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
}
