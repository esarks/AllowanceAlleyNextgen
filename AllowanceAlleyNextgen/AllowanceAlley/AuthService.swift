import Foundation
import Combine
import Supabase

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    // MARK: - Published state
    @Published var isAuthenticated = false
    @Published var isEmailVerified = false
    @Published var currentUser: AppUser?          // keep your existing type
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

    /// Clear local auth-related state (useful on app start while developing).
    func resetAuthenticationState() {
        Task { await signOutLocally() }
    }

    // MARK: - Sign Up / Sign In / Sign Out

    /// Email/password sign-up; Supabase emails a 6-digit OTP.
    func signUp(email: String, password: String, familyName: String?) async throws {
        let result = try await supabase.client.auth.signUp(email: email, password: password)
        let user = result.user                               // non-optional in current SDK
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
        await refreshSession()
    }

    /// Non-throwing sign-out: always clears local state so UI returns to login.
    func signOut() async {
        do { try await supabase.client.auth.signOut() }
        catch { print("signOut error:", error) }     // keep for dev visibility
        await signOutLocally()
    }

    // MARK: - OTP (real Supabase verification)
    func resendVerificationCode() async throws {
        guard let email = pendingVerificationEmail else { throw VerificationError.invalid }
        try await supabase.client.auth.resend(email: email, type: .signup)
    }

    func verifyCode(_ code: String) async throws {
        guard let email = pendingVerificationEmail else { throw VerificationError.invalid }

        try await supabase.client.auth.verifyOTP(email: email, token: code, type: .signup)

        let session = try await supabase.client.auth.session
        await applySession(session)

        pendingVerificationEmail = nil
        isAuthenticated = true
        isEmailVerified = true

        try await postLoginBootstrap(familyName: nil)
    }

    // MARK: - Private
    private func postLoginBootstrap(familyName: String?) async throws {
        let session = try await supabase.client.auth.session
        await applySession(session)
        // e.g., ensure family exists using `familyName` if you choose to.
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

        // TODO: replace with your real profile fetch
        await loadUserProfile(supabaseUser: session.user)

        isAuthenticated = true
    }

    private func startAuthListener() {
        authStateListener?.cancel()
        authStateListener = Task { [weak self] in
            guard let self else { return }
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

    // Minimal placeholder so UI can run before you wire your real fetch.
    private func loadUserProfile(supabaseUser: User) async {
        if currentUser == nil {
            let email = supabaseUser.email ?? ""
            let display = email.split(separator: "@").first.map(String.init) ?? "User"
            currentUser = AppUser(
                id: supabaseUser.id.uuidString,
                role: .parent,                 // adjust if you store roles elsewhere
                email: email,
                displayName: display,
                familyId: nil,
                createdAt: Date()
            )
        }
    }

    enum VerificationError: Error { case invalid }
}
