# Swift Sources

_Generated on Sat Aug 23 13:49:54 EDT 2025 from directory: ._

## File: AdditionalViews.swift

```swift
import SwiftUI

// MARK: - Reports

struct ReportsView: View {
    @EnvironmentObject var choreService: ChoreService
    @EnvironmentObject var familyService: FamilyService
    @EnvironmentObject var rewardsService: RewardsService

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Family Reports")
                        .font(.title2)
                        .fontWeight(.semibold)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Coming Soon").font(.headline)
                        Text("• Weekly progress reports")
                        Text("• Points earned history")
                        Text("• Chore completion trends")
                        Text("• Family achievements")
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Reports")
        }
    }
}

// MARK: - Parent Settings

struct ParentSettingsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var notificationsService: NotificationsService

    // Safe strings for display
    private var emailText: String {
        // Prefer AppUser.email, fall back to Supabase user’s email
        authService.currentUser?.email
        ?? authService.currentSupabaseUser?.email
        ?? "Unknown"
    }

    private var familyNameText: String {
        authService.currentUser?.displayName ?? "Not set"
    }

    var body: some View {
        NavigationView {
            List {
                Section("Account") {
                    HStack {
                        Text("Email"); Spacer()
                        Text(emailText).foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Family Name"); Spacer()
                        Text(familyNameText).foregroundColor(.secondary)
                    }
                }

                Section("Notifications") {
                    Toggle("Allow Notifications", isOn: $notificationsService.isAuthorized)
                        .disabled(true)

                    Button("Request Notification Permission") {
                        notificationsService.requestPermissions()
                    }
                }

                Section("Data") {
                    Button("Export Family Data") { /* TODO */ }
                    Button("Import Data") { /* TODO */ }
                }

                Section {
                    Button(role: .destructive) {
                        Task { await authService.signOut() }
                    } label: {
                        Text("Sign Out")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Child Settings

struct ChildSettingsView: View {
    let childId: String
    @EnvironmentObject var authService: AuthService

    var body: some View {
        NavigationView {
            List {
                Section("About Me") {
                    HStack {
                        Text("Child ID"); Spacer()
                        Text(childId).font(.caption).foregroundColor(.secondary)
                    }
                }

                Section("Privacy") {
                    Text("Your data is safe with us")
                        .font(.caption).foregroundColor(.secondary)
                }

                Section {
                    Button(role: .destructive) {
                        Task { await authService.signOut() }
                    } label: {
                        Text("Sign Out")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Child Rewards

struct ChildRewardsView: View {
    let childId: String
    @EnvironmentObject var rewardsService: RewardsService

    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        NavigationView {
            List {
                if let error {
                    Text(error).foregroundColor(.red)
                }

                if rewardsService.rewards.isEmpty && !isLoading {
                    Text("No rewards yet").foregroundColor(.secondary)
                }

                ForEach(rewardsService.rewards) { reward in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(reward.name).font(.headline)
                            Text("\(reward.costPoints) points")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Redeem") {
                            Task {
                                do {
                                    try await rewardsService.requestRedemption(
                                        rewardId: reward.id,
                                        memberId: childId
                                    )
                                } catch {
                                    self.error = error.localizedDescription
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Rewards")
            .task { await loadData() }
            .refreshable { await loadData() }
        }
    }

    private func loadData() async {
        isLoading = true
        defer { isLoading = false }
        await rewardsService.loadAll()
    }
}

// Back-compat wrapper
struct RewardsView: View {
    let childId: String
    var body: some View { ChildRewardsView(childId: childId) }
}
```

## File: AllowanceAlleyApp.swift

```swift
import SwiftUI

@main
struct AllowanceAlleyApp: App {
    @StateObject private var authService          = AuthService.shared
    @StateObject private var familyService        = FamilyService.shared
    @StateObject private var choreService         = ChoreService.shared
    @StateObject private var rewardsService       = RewardsService.shared
    @StateObject private var notificationsService = NotificationsService.shared
    @StateObject private var imageStore           = ImageStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(familyService)
                .environmentObject(choreService)
                .environmentObject(rewardsService)
                .environmentObject(notificationsService)
                .environmentObject(imageStore)
                .onAppear {
                    authService.initialize()
                }
        }
    }
}
```

## File: AppConfig.swift

```swift
import Foundation
import CoreGraphics

struct AppConfig {
    static let supabaseURL: String = {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              !url.isEmpty else {
            fatalError("SUPABASE_URL not found in Info.plist")
        }
        return url
    }()
    
    static let supabaseAnonKey: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              !key.isEmpty else {
            fatalError("SUPABASE_ANON_KEY not found in Info.plist")
        }
        return key
    }()
    
    static let appName = "Allowance Alley"
    static let minimumIOSVersion = "15.0"
    
    static let defaultDueSoonMinutes = 60
    static let maxNotificationDays = 7
    
    static let maxImageSizeMB = 5
    static let imageCompressionQuality: CGFloat = 0.8
    static let thumbnailSize = CGSize(width: 200, height: 200)
    
    static let syncBatchSize = 50
    static let maxRetryAttempts = 3
    static let syncIntervalSeconds: TimeInterval = 30
}
```

## File: AppSupabase.swift

```swift
import Foundation
import Supabase

final class AppSupabase {
    static let shared = AppSupabase()
    let client: SupabaseClient
    
    private init() {
        guard let url = URL(string: AppConfig.supabaseURL) else {
            fatalError("Invalid SUPABASE_URL")
        }
        
        // Updated Supabase client initialization
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: AppConfig.supabaseAnonKey
        )
    }
}
```

## File: AuthService.swift

```swift
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

        // Load your profile from DB so familyId is set
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

    // MARK: - Profile load (real fetch)
    private func loadUserProfile(supabaseUser: User) async {
        do {
            if let profile = try await DatabaseAPI.shared.fetchProfile(userId: supabaseUser.id.uuidString) {
                currentUser = profile
            } else {
                // Minimal bootstrap if profiles row doesn't exist yet (optional)
                currentUser = AppUser(
                    id: supabaseUser.id.uuidString,
                    role: .parent,
                    email: supabaseUser.email ?? "",
                    displayName: (supabaseUser.email ?? "").split(separator: "@").first.map(String.init) ?? "User",
                    familyId: nil,
                    createdAt: Date()
                )
            }
        } catch {
            print("Profile load failed: \(error)")
        }
    }

    enum VerificationError: Error { case invalid }
}
```

## File: AuthenticationView.swift

```swift
import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authService: AuthService

    @State private var email = ""
    @State private var password = ""
    @State private var familyName = ""

    @State private var signinError: String?
    @State private var signupError: String?
    @State private var working = false

    var body: some View {
        NavigationView {
            Form {
                Section("Account") {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                }

                Section("Family (optional for sign up)") {
                    TextField("Family Name", text: $familyName)
                }

                if let signinError { Text(signinError).foregroundColor(.red) }
                if let signupError { Text(signupError).foregroundColor(.red) }

                Section {
                    Button(working ? "Signing In…" : "Sign In") {
                        Task { await signIn() }
                    }
                    .disabled(working || email.isEmpty || password.isEmpty)

                    Button(working ? "Creating…" : "Sign Up") {
                        Task { await signUp() }
                    }
                    .disabled(working || email.isEmpty || password.isEmpty)
                }
            }
            .navigationTitle("Welcome")
        }
    }

    private func signIn() async {
        working = true; defer { working = false }
        signinError = nil
        do {
            try await authService.signIn(email: email.trimmingCharacters(in: .whitespaces),
                                         password: password)
        } catch {
            signinError = error.localizedDescription
        }
    }

    private func signUp() async {
        working = true; defer { working = false }
        signupError = nil
        do {
            try await authService.signUp(email: email.trimmingCharacters(in: .whitespaces),
                                         password: password,
                                         familyName: familyName.trimmingCharacters(in: .whitespaces))
        } catch {
            signupError = error.localizedDescription
        }
    }
}
```

## File: ChoreService.swift

```swift
import Foundation
import Combine

@MainActor
final class ChoreService: ObservableObject {
    static let shared = ChoreService()

    @Published private(set) var chores: [Chore] = []
    @Published private(set) var assignments: [ChoreAssignment] = []
    @Published private(set) var completions: [ChoreCompletion] = []
    @Published private(set) var pendingApprovals: [ChoreCompletion] = []

    private let auth = AuthService.shared
    private let db = DatabaseAPI.shared
    private init() {}

    // Load everything needed for the dashboard
    func loadAll() async {
        guard let familyId = auth.currentUser?.familyId ?? auth.currentUser?.id else { return }
        async let a = loadChores(familyId: familyId)
        async let b = loadAssignments(familyId: familyId)
        async let c = loadCompletions(familyId: familyId)
        _ = await (a, b, c)
    }

    func loadChores(familyId: String) async {
        do { chores = try await db.fetchChores(familyId: familyId) } catch { print(error) }
    }

    func loadAssignments(familyId: String) async {
        do { assignments = try await db.fetchAssignments(familyId: familyId) } catch { print(error) }
    }

    func loadCompletions(familyId: String) async {
        do {
            completions = try await db.fetchCompletions(familyId: familyId)
            pendingApprovals = completions.filter { $0.status == .pending }
        } catch { print(error) }
    }

    // Create a chore and optional assignments
    func createChore(_ chore: Chore, assignedTo childIds: [String]) async throws {
        let created = try await db.createChore(chore)
        chores.append(created)

        for id in childIds {
            let a = try await db.assignChore(choreId: created.id, memberId: id, due: Date().addingTimeInterval(24*3600))
            assignments.append(a)
        }
    }

    // Child marks complete (optionally with photo URL you’ve stored in Storage)
    func completeChore(assignmentId: String, photoURL: String? = nil) async throws {
        let completion = ChoreCompletion(
            assignmentId: assignmentId,
            submittedBy: auth.currentUser?.id,
            photoURL: photoURL,
            status: .pending,
            completedAt: Date()
        )
        let saved = try await db.submitCompletion(completion)
        completions.insert(saved, at: 0)
        pendingApprovals.insert(saved, at: 0)
    }

    // Parent approves / rejects
    func approveCompletion(_ completion: ChoreCompletion) async throws {
        guard let reviewer = auth.currentUser?.id else { return }
        let updated = try await db.reviewCompletion(id: completion.id, status: "approved", reviewedBy: reviewer)
        replaceCompletion(updated)
    }

    func rejectCompletion(_ completion: ChoreCompletion) async throws {
        guard let reviewer = auth.currentUser?.id else { return }
        let updated = try await db.reviewCompletion(id: completion.id, status: "rejected", reviewedBy: reviewer)
        replaceCompletion(updated)
    }

    private func replaceCompletion(_ updated: ChoreCompletion) {
        if let i = completions.firstIndex(where: { $0.id == updated.id }) { completions[i] = updated }
        pendingApprovals.removeAll { $0.id == updated.id || updated.status != .pending }
        if updated.status == .pending { pendingApprovals.append(updated) }
    }

    // Utility used by ChildChoresView in some builds
    func getTodayAssignments(for memberId: String) -> [ChoreAssignment] {
        let cal = Calendar.current
        return assignments.filter { a in
            guard let due = a.dueDate else { return false }
            return cal.isDateInToday(due) && a.memberId == memberId
        }
    }
}
```

## File: ContentView.swift

```swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var choreService: ChoreService
    @EnvironmentObject var rewardsService: RewardsService
    @EnvironmentObject var familyService: FamilyService

    var body: some View {
        Group {
            if authService.isAuthenticated {
                if let user = authService.currentUser {
                    switch user.role {
                    case .parent:
                        ParentMainView()
                            .task {
                                await familyService.loadChildren()
                                await choreService.loadAll()
                                await rewardsService.loadAll()
                            }
                    case .child:
                        ChildMainView(childId: user.id)
                            .task {
                                await familyService.loadChildren()
                                await choreService.loadAll()
                                await rewardsService.loadAll()
                            }
                    }
                } else {
                    ProgressView("Loading profile…")
                }
            } else if authService.pendingVerificationEmail != nil {
                EmailVerificationView()
            } else {
                AuthenticationView()
            }
        }
    }
}
```

## File: CoreDataStack.swift

```swift
import Foundation
import CoreData

final class CoreDataStack {
    static let shared = CoreDataStack()
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "AllowanceAlley")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()
    
    var context: NSManagedObjectContext { persistentContainer.viewContext }
    var backgroundContext: NSManagedObjectContext { persistentContainer.newBackgroundContext() }
    
    func save() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do { try context.save() } catch { print("Failed to save context: \(error)") }
        }
    }
}
```

## File: DashboardView.swift

```swift
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var familyService: FamilyService
    @EnvironmentObject var choreService: ChoreService
    @EnvironmentObject var rewardsService: RewardsService

    var body: some View {
        NavigationView {
            List {
                Text("Dashboard").font(.headline)

                Section {
                    Text("Children: \(familyService.children.count)")
                    Text("Pending approvals: \(choreService.pendingApprovals.count)")
                }
            }
            .navigationTitle("Dashboard")
            .task { await loadDashboardData() }
        }
    }

    private func loadDashboardData() async {
        // Load family + children
        await familyService.loadFamily()
        await familyService.loadChildren()

        // Load chores/assignments/completions + rewards/redemptions
        await choreService.loadAll()
        await rewardsService.loadAll()
    }
}
```

## File: DatabaseAPI.swift

```swift
import Foundation
import Supabase

struct DatabaseAPI {
    static let shared = DatabaseAPI()
    private let client = AppSupabase.shared.client
    private init() {}

    // MARK: - Families / Children

    func createFamily(name: String) async throws -> Family {
        try await client
            .from("families")
            .insert(["name": name], returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }

    func fetchFamily(for userId: String) async throws -> Family? {
        let rows: [Family] = try await client
            .from("families")
            .select()
            .eq("owner_user_id", value: userId)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    func createChild(familyId: String, displayName: String) async throws -> Child {
        try await client
            .from("children")
            .insert([
                "family_id": familyId,
                "display_name": displayName
            ], returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }

    func fetchChildren(familyId: String) async throws -> [Child] {
        try await client
            .from("children")
            .select()
            .eq("family_id", value: familyId)
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    func updateChild(_ child: Child) async throws -> Child {
        try await client
            .from("children")
            .update(child, returning: .representation)
            .eq("id", value: child.id)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteChild(id: String) async throws {
        _ = try await client
            .from("children")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Profiles

    func fetchProfile(userId: String) async throws -> AppUser? {
        let rows: [AppUser] = try await client
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    // MARK: - Chores

    func fetchChores(familyId: String) async throws -> [Chore] {
        try await client
            .from("chores")
            .select()
            .eq("family_id", value: familyId)
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    func createChore(_ chore: Chore) async throws -> Chore {
        try await client
            .from("chores")
            .insert(chore, returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }

    func updateChore(_ chore: Chore) async throws -> Chore {
        try await client
            .from("chores")
            .update(chore, returning: .representation)
            .eq("id", value: chore.id)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteChore(id: String) async throws {
        _ = try await client
            .from("chores")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Assignments

    func assignChore(choreId: String, memberId: String, due: Date) async throws -> ChoreAssignment {
        try await client
            .from("chore_assignments")
            .insert([
                "chore_id": choreId,
                "member_id": memberId,
                "due_date": ISO8601DateFormatter().string(from: due)
            ], returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }

    func fetchAssignments(familyId: String) async throws -> [ChoreAssignment] {
        try await client
            .from("chore_assignments")
            .select()
            .eq("family_id", value: familyId)
            .execute()
            .value
    }

    // MARK: - Completions

    func submitCompletion(_ completion: ChoreCompletion) async throws -> ChoreCompletion {
        try await client
            .from("chore_completions")
            .insert(completion, returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }

    func reviewCompletion(id: String, status: String, reviewedBy: String) async throws -> ChoreCompletion {
        try await client
            .from("chore_completions")
            .update([
                "status": status,
                "reviewed_by": reviewedBy,
                "reviewed_at": ISO8601DateFormatter().string(from: Date())
            ], returning: .representation)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
    }

    func fetchCompletions(familyId: String) async throws -> [ChoreCompletion] {
        try await client
            .from("chore_completions")
            .select()
            .eq("family_id", value: familyId)
            .order("completed_at", ascending: false)
            .execute()
            .value
    }

    // MARK: - Rewards

    func fetchRewards(familyId: String) async throws -> [Reward] {
        try await client
            .from("rewards")
            .select()
            .eq("family_id", value: familyId)
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    func createReward(_ reward: Reward) async throws -> Reward {
        try await client
            .from("rewards")
            .insert(reward, returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }

    func updateReward(_ reward: Reward) async throws -> Reward {
        try await client
            .from("rewards")
            .update(reward, returning: .representation)
            .eq("id", value: reward.id)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteReward(id: String) async throws {
        _ = try await client
            .from("rewards")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Redemptions

    func requestRedemption(rewardId: String, memberId: String) async throws -> RewardRedemption {
        try await client
            .from("reward_redemptions")
            .insert([
                "reward_id": rewardId,
                "member_id": memberId,
                "status": "requested",
                "requested_at": ISO8601DateFormatter().string(from: Date())
            ], returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }

    func setRedemptionStatus(id: String, status: String, decidedBy: String) async throws -> RewardRedemption {
        try await client
            .from("reward_redemptions")
            .update([
                "status": status,
                "decided_by": decidedBy,
                "decided_at": ISO8601DateFormatter().string(from: Date())
            ], returning: .representation)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
    }

    func fetchRedemptions(familyId: String) async throws -> [RewardRedemption] {
        try await client
            .from("reward_redemptions")
            .select()
            .eq("family_id", value: familyId)
            .order("requested_at", ascending: false)
            .execute()
            .value
    }

    // MARK: - Points ledger

    func addLedgerEntry(_ entry: PointsLedger) async throws -> PointsLedger {
        try await client
            .from("points_ledger")
            .insert(entry, returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }

    func fetchLedger(familyId: String, memberId: String) async throws -> [PointsLedger] {
        try await client
            .from("points_ledger")
            .select()
            .eq("family_id", value: familyId)
            .eq("member_id", value: memberId)
            .order("created_at", ascending: false)
            .execute()
            .value
    }
}
```

## File: EmailVerificationView.swift

```swift
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
```

## File: FamilyService.swift

```swift
import Foundation
import Combine

@MainActor
final class FamilyService: ObservableObject {
    static let shared = FamilyService()

    @Published private(set) var family: Family?
    @Published private(set) var children: [Child] = []

    private let auth = AuthService.shared
    private let db = DatabaseAPI.shared
    private init() {}

    func loadFamily() async {
        guard let userId = auth.currentUser?.id else { return }
        do { family = try await db.fetchFamily(for: userId) } catch { print(error) }
    }

    func loadChildren() async {
        guard let familyId = auth.currentUser?.familyId ?? auth.currentUser?.id else { return }
        do { children = try await db.fetchChildren(familyId: familyId) } catch { print(error) }
    }

    func createChild(name: String, birthdate: Date? = nil, pin: String? = nil) async throws {
        guard let familyId = auth.currentUser?.familyId ?? auth.currentUser?.id else { return }
        let created = try await db.createChild(familyId: familyId, displayName: name)
        children.append(created)
    }

    func updateChild(_ child: Child) async throws {
        let updated = try await db.updateChild(child)
        if let i = children.firstIndex(where: { $0.id == updated.id }) { children[i] = updated }
    }

    func deleteChild(_ child: Child) async throws {
        try await db.deleteChild(id: child.id)
        children.removeAll { $0.id == child.id }
    }
}
```

## File: ImageStore.swift

```swift
import Foundation
import SwiftUI

@MainActor
class ImageStore: ObservableObject {
    static let shared = ImageStore()
    
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024
    }
    
    func processImage(_ uiImage: UIImage) -> Data? {
        let resizedImage = resizeImage(uiImage, targetSize: AppConfig.thumbnailSize)
        return resizedImage.jpegData(compressionQuality: AppConfig.imageCompressionQuality)
    }
    
    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let ratio = min(widthRatio, heightRatio)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? image
    }
    
    func uploadImage(_ image: UIImage, fileName: String? = nil) async throws -> String {
        guard let imageData = processImage(image) else { throw ImageError.processingFailed }
        let fileSizeMB = Double(imageData.count) / (1024 * 1024)
        guard fileSizeMB <= Double(AppConfig.maxImageSizeMB) else { throw ImageError.fileTooLarge }
        isUploading = true
        uploadProgress = 0.0
        defer { Task { isUploading = false; uploadProgress = 0.0 } }
        let fileName = fileName ?? "\(UUID().uuidString).jpg"
        let path = "chore_photos/\(fileName)"
        uploadProgress = 0.5
        let url = try await StorageAPI.shared.uploadImage(imageData, bucket: "photos", path: path)
        uploadProgress = 1.0
        cache.setObject(image, forKey: NSString(string: url))
        return url
    }
    
    func downloadImage(from url: String) async throws -> UIImage {
        if let cachedImage = cache.object(forKey: NSString(string: url)) { return cachedImage }
        guard let urlComponents = URLComponents(string: url),
              let last = urlComponents.path.split(separator: "/").last else { throw ImageError.invalidURL }
        let data = try await StorageAPI.shared.downloadImage(bucket: "photos", path: "chore_photos/\(last)")
        guard let image = UIImage(data: data) else { throw ImageError.invalidImageData }
        cache.setObject(image, forKey: NSString(string: url))
        return image
    }
    
    func clearCache() { cache.removeAllObjects() }
    func getCachedImage(for url: String) -> UIImage? { cache.object(forKey: NSString(string: url)) }
}

enum ImageError: LocalizedError {
    case processingFailed, fileTooLarge, invalidURL, invalidImageData, uploadFailed, downloadFailed
    var errorDescription: String? {
        switch self {
        case .processingFailed: return "Failed to process image"
        case .fileTooLarge: return "Image file is too large"
        case .invalidURL: return "Invalid image URL"
        case .invalidImageData: return "Invalid image data"
        case .uploadFailed: return "Failed to upload image"
        case .downloadFailed: return "Failed to download image"
        }
    }
}
```

## File: MainsView.swift

```swift
//
//  MainsView.swift
//  AllowanceAlleyNextgen
//
//  Created by Paul Marshall on 8/23/25.
//
import SwiftUI

// MARK: - Parent Main

struct ParentMainView: View {
    var body: some View {
        TabView {
            ParentDashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            ReportsView()
                .tabItem { Label("Reports", systemImage: "chart.bar.fill") }

            ParentSettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

// MARK: - Child Main

struct ChildMainView: View {
    let childId: String

    var body: some View {
        TabView {
            ChildChoresView(childId: childId)
                .tabItem { Label("Chores", systemImage: "checklist") }

            ChildRewardsView(childId: childId)
                .tabItem { Label("Rewards", systemImage: "gift.fill") }

            ChildSettingsView(childId: childId)
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

// MARK: - Child Chores (simple placeholder hooked to your services)

struct ChildChoresView: View {
    let childId: String
    @EnvironmentObject var choreService: ChoreService

    @State private var todays: [ChoreAssignment] = []

    var body: some View {
        NavigationView {
            List {
                if todays.isEmpty {
                    Text("No chores due today 🎉").foregroundColor(.secondary)
                } else {
                    ForEach(todays, id: \.id) { a in
                        VStack(alignment: .leading) {
                            Text(choreTitle(for: a.choreId))
                                .font(.headline)
                            if let due = a.dueDate {
                                Text("Due: \(due.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Chores")
            .task {
                // use what you already load into the service
                todays = choreService.getTodayAssignments(for: childId)
            }
        }
    }

    private func choreTitle(for choreId: String) -> String {
        choreService.chores.first(where: { $0.id == choreId })?.title ?? "Chore"
    }
}

```

## File: Models.swift

```swift
import Foundation

// MARK: - Enums

public enum UserRole: String, Codable, CaseIterable {
    case parent = "parent"
    case child = "child"
}

public enum CompletionStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
}

public enum RedemptionStatus: String, Codable, CaseIterable {
    case requested = "requested"
    case approved = "approved"
    case rejected = "rejected"
    case fulfilled = "fulfilled"
}

public enum PointsEvent: String, Codable, CaseIterable {
    case choreCompleted = "chore_completed"
    case rewardRedeemed = "reward_redeemed"
    case bonus = "bonus"
    case penalty = "penalty"
}

// MARK: - Core Models

public struct Family: Identifiable, Codable, Equatable {
    public var id: String
    public var ownerId: String
    public var name: String
    public var createdAt: Date
    
    public init(id: String = UUID().uuidString, ownerId: String, name: String, createdAt: Date = Date()) {
        self.id = id
        self.ownerId = ownerId
        self.name = name
        self.createdAt = createdAt
    }
}

public struct Child: Identifiable, Codable, Equatable {
    public var id: String
    public var parentUserId: String
    public var name: String
    public var birthdate: Date?
    public var avatarURL: String?
    public var createdAt: Date
    
    public init(id: String = UUID().uuidString, parentUserId: String, name: String, birthdate: Date? = nil, avatarURL: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.parentUserId = parentUserId
        self.name = name
        self.birthdate = birthdate
        self.avatarURL = avatarURL
        self.createdAt = createdAt
    }
    
    public var age: Int? {
        guard let birthdate = birthdate else { return nil }
        return Calendar.current.dateComponents([.year], from: birthdate, to: Date()).year
    }
}

public struct Chore: Identifiable, Codable, Equatable {
    public var id: String
    public var familyId: String
    public var title: String
    public var description: String?
    public var points: Int
    public var requirePhoto: Bool
    public var recurrence: String?
    public var parentUserId: String
    public var createdAt: Date
    
    public init(id: String = UUID().uuidString, familyId: String, title: String, description: String? = nil, points: Int, requirePhoto: Bool = false, recurrence: String? = nil, parentUserId: String, createdAt: Date = Date()) {
        self.id = id
        self.familyId = familyId
        self.title = title
        self.description = description
        self.points = points
        self.requirePhoto = requirePhoto
        self.recurrence = recurrence
        self.parentUserId = parentUserId
        self.createdAt = createdAt
    }
}

public struct ChoreAssignment: Identifiable, Codable, Equatable {
    public var id: String
    public var choreId: String
    public var memberId: String
    public var dueDate: Date?
    public var createdAt: Date
    
    public init(id: String = UUID().uuidString, choreId: String, memberId: String, dueDate: Date? = nil, createdAt: Date = Date()) {
        self.id = id
        self.choreId = choreId
        self.memberId = memberId
        self.dueDate = dueDate
        self.createdAt = createdAt
    }
}

public struct ChoreCompletion: Identifiable, Codable, Equatable {
    public var id: String
    public var assignmentId: String
    public var submittedBy: String?
    public var photoURL: String?
    public var status: CompletionStatus
    public var completedAt: Date?
    public var reviewedBy: String?
    public var reviewedAt: Date?
    
    public init(id: String = UUID().uuidString, assignmentId: String, submittedBy: String? = nil, photoURL: String? = nil, status: CompletionStatus = .pending, completedAt: Date? = nil, reviewedBy: String? = nil, reviewedAt: Date? = nil) {
        self.id = id
        self.assignmentId = assignmentId
        self.submittedBy = submittedBy
        self.photoURL = photoURL
        self.status = status
        self.completedAt = completedAt
        self.reviewedBy = reviewedBy
        self.reviewedAt = reviewedAt
    }
}

public struct Reward: Identifiable, Codable, Equatable {
    public var id: String
    public var familyId: String
    public var name: String
    public var costPoints: Int
    public var createdAt: Date
    
    public init(id: String = UUID().uuidString, familyId: String, name: String, costPoints: Int, createdAt: Date = Date()) {
        self.id = id
        self.familyId = familyId
        self.name = name
        self.costPoints = costPoints
        self.createdAt = createdAt
    }
}

public struct RewardRedemption: Identifiable, Codable, Equatable {
    public var id: String
    public var rewardId: String
    public var memberId: String
    public var status: RedemptionStatus
    public var requestedAt: Date?
    public var decidedBy: String?
    public var decidedAt: Date?
    
    public init(id: String = UUID().uuidString, rewardId: String, memberId: String, status: RedemptionStatus = .requested, requestedAt: Date? = nil, decidedBy: String? = nil, decidedAt: Date? = nil) {
        self.id = id
        self.rewardId = rewardId
        self.memberId = memberId
        self.status = status
        self.requestedAt = requestedAt
        self.decidedBy = decidedBy
        self.decidedAt = decidedAt
    }
}

public struct PointsLedger: Identifiable, Codable, Equatable {
    public var id: String
    public var familyId: String
    public var memberId: String
    public var delta: Int
    public var reason: String?
    public var event: PointsEvent
    public var createdAt: Date
    
    public init(id: String = UUID().uuidString, familyId: String, memberId: String, delta: Int, reason: String? = nil, event: PointsEvent, createdAt: Date = Date()) {
        self.id = id
        self.familyId = familyId
        self.memberId = memberId
        self.delta = delta
        self.reason = reason
        self.event = event
        self.createdAt = createdAt
    }
}

public struct AppUser: Identifiable, Codable, Equatable {
    public var id: String
    public var role: UserRole
    public var email: String?
    public var displayName: String
    public var familyId: String?
    public var createdAt: Date
    
    public init(id: String = UUID().uuidString, role: UserRole, email: String? = nil, displayName: String, familyId: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.role = role
        self.email = email
        self.displayName = displayName
        self.familyId = familyId
        self.createdAt = createdAt
    }
}

// MARK: - Dashboard Models

public struct DashboardSummary: Codable {
    public var todayAssigned = 0
    public var todayCompleted = 0
    public var thisWeekAssigned = 0
    public var thisWeekCompleted = 0
    public var pendingApprovals = 0
    public var childrenStats: [ChildStats] = []
    public var totalPointsEarned = 0
    
    public init() {}
}

public struct ChildStats: Codable {
    public var childId: String
    public var displayName: String
    public var completedChores: Int = 0
    public var pendingChores: Int = 0
    public var weeklyPoints: Int = 0
    public var totalPoints: Int = 0
    
    public init(childId: String, displayName: String) {
        self.childId = childId
        self.displayName = displayName
    }
}

// MARK: - Family Member Model

public struct FamilyMember: Identifiable, Codable, Equatable {
    public var id: String
    public var familyId: String
    public var userId: String?
    public var childName: String?
    public var age: Int?
    public var role: UserRole
    public var createdAt: Date?
    
    public init(id: String = UUID().uuidString, familyId: String, userId: String? = nil, childName: String? = nil, age: Int? = nil, role: UserRole, createdAt: Date? = nil) {
        self.id = id
        self.familyId = familyId
        self.userId = userId
        self.childName = childName
        self.age = age
        self.role = role
        self.createdAt = createdAt
    }
}

// MARK: - Codable Extensions for Database Mapping

extension Family {
    enum CodingKeys: String, CodingKey {
        case id, name
        case ownerId = "owner_id"
        case createdAt = "created_at"
    }
}

extension Child {
    enum CodingKeys: String, CodingKey {
        case id, name, birthdate
        case parentUserId = "parent_user_id"
        case avatarURL = "avatar_url"
        case createdAt = "created_at"
    }
}

extension Chore {
    enum CodingKeys: String, CodingKey {
        case id, title, description, points, recurrence
        case familyId = "family_id"
        case requirePhoto = "require_photo"
        case parentUserId = "parent_user_id"
        case createdAt = "created_at"
    }
}

extension ChoreAssignment {
    enum CodingKeys: String, CodingKey {
        case id
        case choreId = "chore_id"
        case memberId = "member_id"
        case dueDate = "due_date"
        case createdAt = "created_at"
    }
}

extension ChoreCompletion {
    enum CodingKeys: String, CodingKey {
        case id, status
        case assignmentId = "assignment_id"
        case submittedBy = "submitted_by"
        case photoURL = "photo_url"
        case completedAt = "completed_at"
        case reviewedBy = "reviewed_by"
        case reviewedAt = "reviewed_at"
    }
}

extension Reward {
    enum CodingKeys: String, CodingKey {
        case id, name
        case familyId = "family_id"
        case costPoints = "cost_points"
        case createdAt = "created_at"
    }
}

extension RewardRedemption {
    enum CodingKeys: String, CodingKey {
        case id, status
        case rewardId = "reward_id"
        case memberId = "member_id"
        case requestedAt = "requested_at"
        case decidedBy = "decided_by"
        case decidedAt = "decided_at"
    }
}

extension PointsLedger {
    enum CodingKeys: String, CodingKey {
        case id, delta, reason, event
        case familyId = "family_id"
        case memberId = "member_id"
        case createdAt = "created_at"
    }
}

extension AppUser {
    enum CodingKeys: String, CodingKey {
        case id, role, email
        case displayName = "display_name"
        case familyId = "family_id"
        case createdAt = "created_at"
    }
}

extension FamilyMember {
    enum CodingKeys: String, CodingKey {
        case id, role, age
        case familyId = "family_id"
        case userId = "user_id"
        case childName = "child_name"
        case createdAt = "created_at"
    }
}

// MARK: - Date Extensions

public extension Date {
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    func ISO8601String() -> String {
        ISO8601DateFormatter().string(from: self)
    }
}
```

## File: NotificationsService.swift

```swift
import Foundation
import UserNotifications
import Combine

@MainActor
final class NotificationsService: ObservableObject {
    static let shared = NotificationsService()
    
    @Published var isAuthorized = false
    @Published var notificationSettings: [String: NotificationSettings] = [:]
    
    private init() {}
    
    func requestPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, _ in
            Task { @MainActor in self?.isAuthorized = granted }
        }
    }
    
    func checkPermissions() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let authorized = settings.authorizationStatus == .authorized
        isAuthorized = authorized
        return authorized
    }
    
    func scheduleChoreReminder(choreId: String, childId: String, dueDate: Date) {
        guard isAuthorized else { return }
        let content = UNMutableNotificationContent()
        content.title = "Chore Due Soon"
        content.body = "You have a chore due soon. Don't forget to complete it!"
        content.sound = .default
        let triggerDate = Calendar.current.date(byAdding: .hour, value: -1, to: dueDate) ?? dueDate
        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: triggerDate), repeats: false)
        let request = UNNotificationRequest(identifier: "chore_reminder_\(choreId)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleApprovalNotification(for parentId: String) {
        guard isAuthorized else { return }
        let content = UNMutableNotificationContent()
        content.title = "Chore Completed"
        content.body = "A child has completed a chore and needs your approval!"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "approval_needed_\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelNotification(identifier: String) { UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier]) }
    func cancelAllNotifications() { UNUserNotificationCenter.current().removeAllPendingNotificationRequests() }
}

struct NotificationSettings {
    var dueSoonMinutes: Int = 60
    var allowReminders: Bool = true
}
```

## File: ParentDashboardView.swift

```swift
import SwiftUI

struct ParentDashboardView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var familyService: FamilyService
    @EnvironmentObject var choreService: ChoreService
    @EnvironmentObject var rewardsService: RewardsService

    @State private var isLoading = false
    @State private var showingAddChild = false
    @State private var showingAddChore = false
    @State private var showingAddReward = false

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if isLoading {
                        ProgressView("Loading dashboard...")
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        // Welcome Header
                        welcomeHeader

                        // Quick Stats Cards
                        quickStatsSection

                        // Pending Approvals Alert
                        if pendingApprovals > 0 {
                            pendingApprovalsCard
                        }

                        // Children Summary
                        if !familyService.children.isEmpty {
                            childrenSection
                        }

                        // Quick Actions
                        quickActionsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .refreshable { await loadDashboardData() }
            .task { await loadDashboardData() }
            .sheet(isPresented: $showingAddChild) { AddChildView() }
            .sheet(isPresented: $showingAddChore) { AddChoreView() }
            .sheet(isPresented: $showingAddReward) { AddRewardView() }
        }
    }

    // MARK: - Derived metrics

    private var pendingApprovals: Int { choreService.pendingApprovals.count }

    private var todayAssigned: Int {
        let cal = Calendar.current
        return choreService.assignments.filter { a in
            guard let due = a.dueDate else { return false }        // <-- unwrap Date?
            return cal.isDateInToday(due)
        }.count
    }

    private var todayCompleted: Int {
        let cal = Calendar.current
        return choreService.completions.filter { c in
            guard let when = c.completedAt else { return false }   // <-- unwrap Date?
            return cal.isDateInToday(when) && (c.status == .approved || c.status == .pending)
        }.count
    }

    private var weekAssigned: Int {
        let cal = Calendar.current
        let now = Date()
        return choreService.assignments.filter { a in
            guard let d = a.dueDate else { return false }          // <-- unwrap Date?
            return cal.component(.weekOfYear, from: d) == cal.component(.weekOfYear, from: now) &&
                   cal.component(.yearForWeekOfYear, from: d) == cal.component(.yearForWeekOfYear, from: now)
        }.count
    }

    private var weekCompleted: Int {
        let cal = Calendar.current
        let now = Date()
        return choreService.completions.filter { c in
            guard let d = c.completedAt else { return false }      // <-- unwrap Date?
            return cal.component(.weekOfYear, from: d) == cal.component(.weekOfYear, from: now) &&
                   cal.component(.yearForWeekOfYear, from: d) == cal.component(.yearForWeekOfYear, from: now) &&
                   (c.status == .approved || c.status == .pending)
        }.count
    }

    // MARK: - Sections

    private var welcomeHeader: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back!")
                        .font(.title2).fontWeight(.semibold)

                    let famName = familyService.family?.name
                        ?? authService.currentUser?.displayName
                        ?? "Family"
                    Text("\(famName) Family")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Circle()
                    .fill(Color.blue.gradient)
                    .frame(width: 50, height: 50)
                    .overlay(Image(systemName: "person.fill").foregroundColor(.white))
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(16)
        }
    }

    private var quickStatsSection: some View {
        VStack(spacing: 12) {
            HStack { Text("Today's Progress").font(.headline); Spacer() }
            HStack(spacing: 16) {
                StatCard(title: "Today",     completed: todayCompleted, total: todayAssigned, color: .blue)
                StatCard(title: "This Week", completed: weekCompleted,  total: weekAssigned,  color: .green)
            }
        }
    }

    private var pendingApprovalsCard: some View {
        NavigationLink(destination: ApprovalsView()) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill").foregroundColor(.orange)
                        Text("Pending Approvals").font(.headline)
                    }
                    Text("Tap to review and approve completed chores")
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                VStack {
                    Text("\(pendingApprovals)")
                        .font(.title).fontWeight(.bold).foregroundColor(.orange)
                    Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var childrenSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Children").font(.headline); Spacer()
                Text("\(familyService.children.count)")
                    .font(.caption)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
            }
            ForEach(familyService.children) { child in
                ChildSummaryCard(child: child)
            }
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions").font(.headline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                QuickActionButton(icon: "list.bullet.clipboard", title: "Add Chore", color: .blue) {
                    showingAddChore = true
                }
                QuickActionButton(icon: "gift.fill", title: "Add Reward", color: .purple) {
                    showingAddReward = true
                }
                QuickActionButton(icon: "person.badge.plus", title: "Add Child", color: .green) {
                    showingAddChild = true
                }
                QuickActionButton(icon: "chart.bar.fill", title: "View Reports", color: .orange) {
                    // TODO: navigate to reports
                }
            }
        }
    }

    // MARK: - Loading

    private func loadDashboardData() async {
        isLoading = true
        defer { isLoading = false }
        await familyService.loadFamily()
        await familyService.loadChildren()
        await choreService.loadAll()
        await rewardsService.loadAll()
    }
}
```

## File: ParentSheets.swift

```swift
import SwiftUI

// MARK: - Add Child

struct AddChildView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var familyService: FamilyService
    @EnvironmentObject var authService: AuthService

    @State private var name = ""
    @State private var hasBirthdate = false
    @State private var birthdateValue = Date()
    @State private var pin = ""

    @State private var error: String?
    @State private var isSaving = false

    var body: some View {
        NavigationView {
            Form {
                Section("Child") {
                    TextField("First name", text: $name)

                    Toggle("Set birthdate", isOn: $hasBirthdate)

                    if hasBirthdate {
                        DatePicker("Birthdate",
                                   selection: $birthdateValue,
                                   displayedComponents: .date)
                    }

                    TextField("4‑digit PIN (optional)", text: $pin)
                        .keyboardType(.numberPad)
                }

                if let error {
                    Text(error).foregroundColor(.red)
                }
            }
            .navigationTitle("Add Child")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Save") {
                        Task { await save() }
                    }
                    .disabled(isSaving || name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() async {
        isSaving = true; defer { isSaving = false }
        do {
            try await familyService.createChild(name: name.trimmingCharacters(in: .whitespaces),
                                               birthdate: hasBirthdate ? birthdateValue : nil,
                                               pin: pin.isEmpty ? nil : pin)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Add Chore

struct AddChoreView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var choreService: ChoreService
    @EnvironmentObject var familyService: FamilyService
    @EnvironmentObject var authService: AuthService

    @State private var title = ""
    @State private var description = ""
    @State private var points = 10
    @State private var requirePhoto = false

    // Simpler selection model
    @State private var selected: [String: Bool] = [:]

    @State private var error: String?
    @State private var isSaving = false

    var body: some View {
        NavigationView {
            Form {
                Section("Chore") {
                    TextField("Title", text: $title)
                    TextField("Description (optional)", text: $description)
                    Stepper("Points: \(points)", value: $points, in: 0...500, step: 5)
                    Toggle("Require photo proof", isOn: $requirePhoto)
                }

                Section("Assign to") {
                    if familyService.children.isEmpty {
                        Text("No children yet").foregroundColor(.secondary)
                    } else {
                        ForEach(familyService.children) { child in
                            let isOn = Binding(
                                get: { selected[child.id] ?? false },
                                set: { selected[child.id] = $0 }
                            )
                            Toggle(child.name, isOn: isOn)
                        }
                    }
                }

                if let error {
                    Text(error).foregroundColor(.red)
                }
            }
            .navigationTitle("Add Chore")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Save") {
                        Task { await save() }
                    }
                    .disabled(isSaving || title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if selected.isEmpty {
                    var map: [String: Bool] = [:]
                    for c in familyService.children { map[c.id] = false }
                    selected = map
                }
            }
        }
    }

    private func save() async {
        guard let parentId = authService.currentUser?.id,
              let familyId = authService.currentUser?.familyId ?? authService.currentUser?.id else { return }

        isSaving = true; defer { isSaving = false }

        let chore = Chore(
            id: UUID().uuidString,
            familyId: familyId,
            title: title.trimmingCharacters(in: .whitespaces),
            description: description.isEmpty ? nil : description,
            points: points,
            requirePhoto: requirePhoto,
            parentUserId: parentId,
            createdAt: Date()
        )

        do {
            let childIds = selected.filter { $0.value }.map { $0.key }
            try await choreService.createChore(chore, assignedTo: childIds)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Add Reward

struct AddRewardView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var rewardsService: RewardsService
    @EnvironmentObject var authService: AuthService

    @State private var name = ""
    @State private var cost = 50
    @State private var error: String?
    @State private var isSaving = false

    var body: some View {
        NavigationView {
            Form {
                TextField("Reward name", text: $name)
                Stepper("Cost: \(cost) points", value: $cost, in: 0...10000, step: 10)
                if let error { Text(error).foregroundColor(.red) }
            }
            .navigationTitle("Add Reward")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Save") {
                        Task { await save() }
                    }
                    .disabled(isSaving || name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() async {
        guard let familyId = authService.currentUser?.familyId ?? authService.currentUser?.id else { return }
        isSaving = true; defer { isSaving = false }
        do {
            let reward = Reward(
                id: UUID().uuidString,
                familyId: familyId,
                name: name.trimmingCharacters(in: .whitespaces),
                costPoints: cost,
                createdAt: Date()
            )
            try await rewardsService.createReward(reward)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Approvals

struct ApprovalsView: View {
    @EnvironmentObject var choreService: ChoreService
    @State private var error: String?

    var body: some View {
        List {
            if choreService.pendingApprovals.isEmpty {
                Text("Nothing to approve right now").foregroundColor(.secondary)
            } else {
                ForEach(choreService.pendingApprovals) { c in
                    ApprovalRow(completion: c) { action in
                        Task {
                            do {
                                switch action {
                                case .approve: try await choreService.approveCompletion(c)
                                case .reject:  try await choreService.rejectCompletion(c)
                                }
                            } catch { self.error = error.localizedDescription }
                        }
                    }
                }
            }

            if let error { Text(error).foregroundColor(.red) }
        }
        .navigationTitle("Approvals")
    }
}

private enum ApprovalAction { case approve, reject }

private struct ApprovalRow: View {
    let completion: ChoreCompletion
    let onAction: (ApprovalAction) -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Completion \(completion.id.prefix(6))…")
                    .font(.headline)
                Text("Status: \(completion.status.rawValue)")
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            HStack(spacing: 8) {
                Button("Approve") { onAction(.approve) }
                    .buttonStyle(.borderedProminent)
                Button("Reject")  { onAction(.reject)  }
                    .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 6)
    }
}
```

## File: RewardsService.swift

```swift
import Foundation
import Combine

@MainActor
final class RewardsService: ObservableObject {
    static let shared = RewardsService()

    @Published private(set) var rewards: [Reward] = []
    @Published private(set) var redemptions: [RewardRedemption] = []
    @Published private(set) var pointsLedger: [PointsLedger] = []

    private let auth = AuthService.shared
    private let db = DatabaseAPI.shared
    private init() {}

    func loadAll() async {
        guard let familyId = auth.currentUser?.familyId ?? auth.currentUser?.id else { return }
        async let a = loadRewards(familyId: familyId)
        async let b = loadRedemptions(familyId: familyId)
        _ = await (a, b)
    }

    func loadRewards(familyId: String) async {
        do { rewards = try await db.fetchRewards(familyId: familyId) } catch { print(error) }
    }

    func loadRedemptions(familyId: String) async {
        do { redemptions = try await db.fetchRedemptions(familyId: familyId) } catch { print(error) }
    }

    func loadPoints(for memberId: String) async {
        guard let familyId = auth.currentUser?.familyId ?? auth.currentUser?.id else { return }
        do { pointsLedger = try await db.fetchLedger(familyId: familyId, memberId: memberId) } catch { print(error) }
    }

    func createReward(_ reward: Reward) async throws {
        let created = try await db.createReward(reward)
        rewards.append(created)
    }

    func updateReward(_ reward: Reward) async throws {
        let updated = try await db.updateReward(reward)
        if let i = rewards.firstIndex(where: { $0.id == updated.id }) { rewards[i] = updated }
    }

    func deleteReward(_ reward: Reward) async throws {
        try await db.deleteReward(id: reward.id)
        rewards.removeAll { $0.id == reward.id }
    }

    func requestRedemption(rewardId: String, memberId: String) async throws {
        let r = try await db.requestRedemption(rewardId: rewardId, memberId: memberId)
        redemptions.insert(r, at: 0)
    }

    func approveRedemption(_ redemption: RewardRedemption) async throws {
        guard let decider = auth.currentUser?.id else { return }
        let updated = try await db.setRedemptionStatus(id: redemption.id, status: "approved", decidedBy: decider)
        if let i = redemptions.firstIndex(where: { $0.id == updated.id }) { redemptions[i] = updated }

        // optional: write the negative points to the ledger
        if let reward = rewards.first(where: { $0.id == redemption.rewardId }),
           let familyId = auth.currentUser?.familyId ?? auth.currentUser?.id {
            let entry = PointsLedger(
                familyId: familyId,
                memberId: redemption.memberId,
                delta: -reward.costPoints,
                reason: "Redeemed: \(reward.name)",
                event: .rewardRedeemed
            )
            let saved = try await db.addLedgerEntry(entry)
            pointsLedger.insert(saved, at: 0)
        }
    }

    func rejectRedemption(_ redemption: RewardRedemption) async throws {
        guard let decider = auth.currentUser?.id else { return }
        let updated = try await db.setRedemptionStatus(id: redemption.id, status: "rejected", decidedBy: decider)
        if let i = redemptions.firstIndex(where: { $0.id == updated.id }) { redemptions[i] = updated }
    }
}
```

## File: SharedComponents.swift

```swift
import SwiftUI

// Small card used on the dashboard
struct StatCard: View {
    let title: String
    let completed: Int
    let total: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline).foregroundColor(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(completed)").font(.title2).fontWeight(.bold)
                Text("/ \(total)").foregroundColor(.secondary)
            }
            ProgressView(value: total == 0 ? 0 : Double(completed) / Double(max(total, 1)))
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
        .background(color.opacity(0.12))
        .cornerRadius(12)
    }
}

// Square action button used in the grid
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 84)
            .padding(.vertical, 8)
            .background(color.opacity(0.12))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// Row showing a child summary (name + placeholder stats)
struct ChildSummaryCard: View {
    let child: Child

    var body: some View {
        HStack(spacing: 12) {
            Circle().fill(Color.blue.opacity(0.15)).frame(width: 40, height: 40)
                .overlay(Image(systemName: "person.fill").foregroundColor(.blue))
            VStack(alignment: .leading, spacing: 4) {
                Text(child.name) // assumes your Child model exposes `name`
                    .font(.headline)
                Text("Tap a quick action to assign chores or rewards")
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}
```

## File: StorageAPI.swift

```swift
import Foundation
import Supabase

final class StorageAPI {
    static let shared = StorageAPI()
    private let client = AppSupabase.shared.client
    private init() {}

    @discardableResult
    func uploadImage(_ data: Data, bucket: String, path: String) async throws -> String {
        // NEW API: upload(_:data:options:)
        try await client.storage
            .from(bucket)
            .upload(path, data: data)

        let publicURL = try client.storage
            .from(bucket)
            .getPublicURL(path: path)

        return publicURL.absoluteString
    }

    func downloadImage(bucket: String, path: String) async throws -> Data {
        try await client.storage
            .from(bucket)
            .download(path: path)
    }
}
```

