
import Foundation

// MARK: - Email verification helpers for AuthService
// Drop-in extension so EmailVerificationView compiles without changing your core AuthService.
// This stores a DEVELOPMENT-ONLY code and expiry in a static holder.
// Replace implementations with your Supabase calls as needed.

@MainActor
extension AuthService {
    // Exposed read-only property the view expects
    var codeExpiresAt: Date? { VerificationStore.expiresAt }

    // Call when you start a new verification (e.g., after signUp/signInWithOtp)
    func beginVerificationCountdown(seconds: Int = 300) {
        VerificationStore.expiresAt = Date().addingTimeInterval(TimeInterval(seconds))
    }

    // Send or resend a code (DEV only: generate + "send" to console)
    func resendVerificationCode() async throws {
        let code = Self.generateCode()
        VerificationStore.code = code
        beginVerificationCountdown(seconds: 300)
        #if DEBUG
        print("DEV verification code: \(code) (valid until \(VerificationStore.expiresAt!))")
        #endif
    }

    // Verify user-entered code (DEV: compares to stored code)
    func verifyCode(_ code: String) async throws {
        guard let exp = VerificationStore.expiresAt, Date() <= exp else {
            throw VerificationError.expired
        }
        guard code == VerificationStore.code else {
            throw VerificationError.invalid
        }
        // Mark user as authenticated in your real implementation:
        self.isAuthenticated = true
        self.pendingVerificationEmail = nil
    }
}

// MARK: - Helpers

private enum VerificationError: LocalizedError {
    case expired, invalid

    var errorDescription: String? {
        switch self {
        case .expired: return "Your code has expired. Please resend a new code."
        case .invalid: return "That code doesn’t match. Please try again."
        }
    }
}

private enum VerificationStore {
    static var code: String?
    static var expiresAt: Date?
}

private extension AuthService {
    static func generateCode() -> String {
        String((0..<6).map { _ in "0123456789".randomElement()! })
    }
}
