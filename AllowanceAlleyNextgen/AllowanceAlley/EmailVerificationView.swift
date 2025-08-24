// =============================================================================
// FILE: EmailVerificationView.swift (with debug info)
// =============================================================================

import SwiftUI

struct EmailVerificationView: View {
    @EnvironmentObject var auth: AuthService
    @State private var code: String = ""
    @State private var error: String?
    @State private var isVerifying = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Check your email").font(.title2).bold()
            Text("Enter the 6-digit code we sent to \(auth.pendingVerificationEmail ?? "")")
                .multilineTextAlignment(.center)

            // Debug info
            VStack(alignment: .leading, spacing: 4) {
                Text("Debug Info:").font(.caption).bold()
                Text("Auth Status: \(auth.isAuthenticated ? "Authenticated" : "Not Authenticated")")
                    .font(.caption2)
                Text("Pending Email: \(auth.pendingVerificationEmail ?? "None")")
                    .font(.caption2)
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)

            TextField("123456", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 200)

            Button(isVerifying ? "Verifying..." : "Verify") {
                Task { await verifyCode() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(code.count < 6 || isVerifying)

            Button("Resend code") {
                if let email = auth.pendingVerificationEmail {
                    Task { 
                        do {
                            try await auth.sendCode(to: email)
                        } catch {
                            self.error = error.localizedDescription
                        }
                    }
                }
            }.buttonStyle(.bordered)
            
            if let error {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
    }
    
    private func verifyCode() async {
        isVerifying = true
        error = nil
        defer { isVerifying = false }
        
        do {
            try await auth.verifyCode(code)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
