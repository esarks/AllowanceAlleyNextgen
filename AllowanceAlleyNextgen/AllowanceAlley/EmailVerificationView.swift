//
//  EmailVerificationView.swift
//  AllowanceAlleyNextgen
//
//  Created by Paul Marshall on 8/22/25.
//

import SwiftUI

struct EmailVerificationView: View {
    @EnvironmentObject var authService: AuthService
    @State private var inputCode: String = ""
    @State private var error: String?

    // Ticks UI every second so the countdown updates
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var countdownText: String {
        guard let exp = authService.codeExpiresAt else { return "" }
        let remaining = Int(max(0, exp.timeIntervalSinceNow))
        let m = remaining / 60
        let s = remaining % 60
        return String(format: "%02d:%02d", m, s)
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Enter Verification Code")
                .font(.title2)
                .fontWeight(.semibold)

            TextField("6-digit code", text: $inputCode)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.center)

            if let error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.footnote)
            }

            Button("Verify") {
                Task { await verify() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(inputCode.count != 6)

            if !countdownText.isEmpty {
                Text("Code expires in \(countdownText)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Button("Resend Code") {
                Task {
                    do {
                        try await authService.resendVerificationCode()
                    } catch {
                        self.error = error.localizedDescription
                    }
                }
            }
            .font(.footnote)
        }
        .padding()
        .onReceive(timer) { _ in
            // trigger view updates as time passes
            _ = countdownText
        }
    }

    @MainActor
    private func verify() async {
        do {
            try await authService.verifyCode(inputCode)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
