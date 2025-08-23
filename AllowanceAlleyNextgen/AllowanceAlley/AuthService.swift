import Foundation
import Combine
import Supabase

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    // MARK: - Published state
    @Published var isAuthenticated = false
    @Published var isEmailVerified = false
    @Published var currentUser: AppUser?
    @Published var currentSupabaseUser: User?
    @Published var pendingVerificationEmail: String?

    // MARK: - Private
    private let supabase = AppSupabase.shared
    private var authStateListener: Task<Void, Never>?

    private init() {}

    // MARK: - Lifecycle

    func initialize() {
        Task {
            await refreshSession()
            startAuthListener()
        }
    }

    // MARK: - Sign Up / Sign In / Sign Out

    /// Standard email/password sign‑up. Supabase emails a 6‑digit OTP.
    func signUp(email: String, password: String, familyName: String?) async throws {
        let result = try await supabase.client.auth.signUp(email: email, password: password)

        // In your SDK, result.user is non‑optional.
        let user = result.user
        currentSupabaseUser = user
        isEmailVerified = (user.emailConfirmedAt != nil)

        if isEmailVerified {
            try await postLoginBootstrap(familyName: familyName)
        } else {
            pendingVerificationEmail = email
            isAuthenticated = false
        }
    }

    func signIn(email: String, password: String) async throws {
        _ = try await supabase.client.auth.signIn(email: email, password: password)
        try await refreshSession()
    }

    func signOut() async throws {
        try await supabase.client.auth.signOut()
        await signOutLocally()
    }

    // MARK: - OTP Verification (REAL Supabase flow)

    func resendVerificationCode() async throws {
        guard let email = pendingVerificationEmail else { throw VerificationError.invalid }
        // Your SDK expects email: before type:
        try await supabase.client.auth.resend(email: email, type: .signup)
    }

    func verifyCode(_ code: String) async throws {
        guard let email = pendingVerificationEmail else { throw VerificationError.invalid }

        try await supabase.client.auth.verifyOTP(
            email: email,
            token: code,
            type: .signup
        )

        // On success, we should have a valid session/user.
        let session = try await supabase.client.auth.session
        await applySession(session)
        pendingVerificationEmail = nil
        isAuthenticated = true
        isEmailVerified = true

        try await postLoginBootstrap(familyName: nil)
    }

    // MARK: - Private

    private func postLoginBootstrap(familyName: String?) async throws {
        // Place any first‑login bootstrap here (ensure family, etc.).
        let session = try await supabase.client.auth.session
        await applySession(session)
        // Example if you later want:
        // try await FamilyService.shared.ensureFamilyExists(named: familyName)
    }

    private func refreshSession() async {
        do {
            let session = try await supabase.client.auth.session
            await applySession(session)
        } catch {
            await signOutLocally()
        }
    }

    private func applySession(_ session: Session) async {
        currentSupabaseUser = session.user
        isEmailVerified = (session.user.emailConfirmedAt != nil)
        await loadUserProfile(supabaseUser: session.user)
        isAuthenticated = true
    }

    private func startAuthListener() {
        authStateListener?.cancel()
        authStateListener = Task { [weak self] in
            guard let self else { return }
            // Non‑throwing sequence on recent SDKs
            for await _ in self.supabase.client.auth.authStateChanges {
                await self.refreshSession()
            }
        }
    }

    private func signOutLocally() async {
        currentUser = nil
        currentSupabaseUser = nil
        isAuthenticated = false
        isEmailVerified = false
        pendingVerificationEmail = nil
    }

    // MARK: - Profile load (fallback to keep UI working)
    /// Replace with your real fetch from `profiles` (if you have one).
    private func loadUserProfile(supabaseUser: User) async {
        // If you already map to AppUser elsewhere, keep that instead.
        // Your AppUser initializer expects: id, role, email, displayName, familyId, createdAt
        if currentUser == nil {
            let email = supabaseUser.email ?? ""
            let display = supabaseUser.userMetadata?["full_name"] as? String
                ?? email.split(separator: "@").first.map(String.init)
                ?? "User"
            currentUser = AppUser(
                id: supabaseUser.id.uuidString,
                role: .parent,                // adjust if you store per‑user role
                email: email,
                displayName: display,
                familyId: nil,
                createdAt: Date()
            )
        }
    }

    enum VerificationError: Error { case invalid }
}
