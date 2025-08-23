// AuthService.swift
import Foundation
import Combine
import Supabase

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isAuthenticated = false
    @Published var currentUser: AppUser?
    @Published var pendingVerificationEmail: String?

    private let supabase = AppSupabase.shared
    private var authTask: Task<Void, Never>?

    private init() {}

    /// Start observers & prime current session (sync wrapper; spins async tasks)
    func initialize() {
        // Observe auth state changes (v2 yields AuthStateChange with .event/.session)
        authTask = Task { [weak self] in
            guard let self else { return }
            for await change in self.supabase.client.auth.authStateChanges {
                await self.handleAuthEvent(change.event, session: change.session)
            }
        }

        // Prime current session in its own async task
        Task { [weak self] in
            guard let self else { return }
            if let session = try? await self.supabase.client.auth.session {
                try? await self.loadUserFromSession(session)
            } else {
                self.isAuthenticated = false
            }
        }
    }

    private func handleAuthEvent(_ event: AuthChangeEvent, session: Session?) async {
        switch event {
        case .initialSession, .signedIn, .tokenRefreshed, .userUpdated:
            if let s = session ?? (try? await supabase.client.auth.session) {
                try? await loadUserFromSession(s)
            }
        case .signedOut, .userDeleted:
            isAuthenticated = false
            currentUser = nil
            pendingVerificationEmail = nil
        default:
            break
        }
    }

    private func loadUserFromSession(_ session: Session) async throws {
        let user = session.user
        let db = DatabaseAPI.shared
        let roleInfo = try await db.fetchUserRole(userId: user.id.uuidString)
        currentUser = AppUser(
            id: user.id.uuidString,
            email: user.email,
            role: roleInfo?.role ?? .parent,
            familyId: roleInfo?.familyId
        )
        isAuthenticated = true
    }

    // MARK: - Email OTP

    func sendCode(to email: String) async throws {
        try await supabase.client.auth.signInWithOTP(email: email, shouldCreateUser: true)
        pendingVerificationEmail = email
    }

    func verifyCode(_ code: String) async throws {
        guard let email = pendingVerificationEmail else { return }
        try await supabase.client.auth.verifyOTP(email: email, token: code, type: .email)
        pendingVerificationEmail = nil
    }

    func signOut() async {
        do { try await supabase.client.auth.signOut() } catch {
            print("signOut error:", error)
        }
    }
}
