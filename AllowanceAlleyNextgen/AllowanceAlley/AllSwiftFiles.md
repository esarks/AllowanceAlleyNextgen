# Swift Sources

_Generated on Sat Aug 23 15:43:32 EDT 2025 from directory: ._

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

    private var emailText: String {
        authService.currentUser?.email ?? "Unknown"
    }

    var body: some View {
        NavigationView {
            List {
                Section("Account") {
                    HStack {
                        Text("Email"); Spacer()
                        Text(emailText).foregroundColor(.secondary)
                    }
                    if let familyId = authService.currentUser?.familyId {
                        HStack {
                            Text("Family ID"); Spacer()
                            Text(familyId).font(.caption).foregroundColor(.secondary)
                        }
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
                    } label: { Text("Sign Out") }
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
                    } label: { Text("Sign Out") }
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
    @EnvironmentObject var authService: AuthService

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
        guard let famId = authService.currentUser?.familyId else {
            self.error = "No family selected"
            return
        }
        await rewardsService.loadAll(familyId: famId)
    }
}

// MARK: - Back-compat wrapper
/// Accepts current and legacy initializers so existing call sites compile.
struct RewardsView: View {
    let childId: String

    init(childId: String, familyId: String? = nil) {
        self.childId = childId
    }
    init(_ childId: String) { self.childId = childId }          // very old unlabeled usage
    init(familyId: String) { self.childId = familyId }           // very old family-only usage

    var body: some View { ChildRewardsView(childId: childId) }
}
```

## File: AllowanceAlleyApp.swift

```swift

import SwiftUI

@main
struct AllowanceAlleyApp: App {
    @StateObject private var authService = AuthService.shared
    @StateObject private var familyService = FamilyService.shared
    @StateObject private var choreService = ChoreService.shared
    @StateObject private var rewardsService = RewardsService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(familyService)
                .environmentObject(choreService)
                .environmentObject(rewardsService)
                .task {
                    authService.initialize()
                }
        }
    }
}
```

## File: AnyEncodable.swift

```swift

import Foundation

public struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    public init<T: Encodable>(_ value: T) {
        _encode = value.encode
    }

    public func encode(to encoder: Encoder) throws {
        try _encode(encoder)
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
// AppSupabase.swift — collision-proof version
import Foundation
import Supabase

// Use a unique name so it can't collide with any previous 'AppConfig'.
enum AppEnv {
    static let url: URL = {
        if let env = ProcessInfo.processInfo.environment["SUPABASE_URL"],
           let u = URL(string: env) { return u }
        if let s = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
           let u = URL(string: s) { return u }
        preconditionFailure("Missing SUPABASE_URL. Provide ENV or Info.plist.")
    }()

    static let anonKey: String = {
        if let k = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] { return k }
        if let k = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String { return k }
        preconditionFailure("Missing SUPABASE_ANON_KEY. Provide ENV or Info.plist.")
    }()
}

final class AppSupabase {
    static let shared = AppSupabase()
    let client: SupabaseClient

    private init() {
        client = SupabaseClient(supabaseURL: AppEnv.url, supabaseKey: AppEnv.anonKey)
    }
}
```

## File: AuthService.swift

```swift
// AuthService.swift — Supabase Swift v2 friendly, no mock services
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
        // Observe auth state changes (v2 exposes `AuthStateChange` with `event` and `session`)
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
            if let s = session {
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
```

## File: AuthenticationView.swift

```swift

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

    func loadAll(for familyId: String) async {
        async let a = loadChores(familyId: familyId)
        async let b = loadAssignments(familyId: familyId)
        async let c = loadCompletions(familyId: familyId)
        _ = await (a, b, c)
    }

    func loadChores(familyId: String) async {
        do { chores = try await db.fetchChores(familyId: familyId) } catch { print(error) }
    }

    func loadAssignments(familyId: String) async {
        do { assignments = try await db.fetchAssignmentsForFamily(familyId: familyId) } catch { print(error) }
    }

    func loadCompletions(familyId: String) async {
        do {
            completions = try await db.fetchCompletionsForFamily(familyId: familyId)
            pendingApprovals = completions.filter { $0.status == .pending }
        } catch { print(error) }
    }

    func createChore(familyId: String, title: String, description: String?, points: Int, requirePhoto: Bool, recurrence: String?) async throws -> Chore {
        guard let parentId = auth.currentUser?.id else { throw NSError(domain: "Auth", code: 401) }
        let created = try await db.createChore(familyId: familyId, title: title, description: description, points: points, requirePhoto: requirePhoto, recurrence: recurrence, parentUserId: parentId)
        chores.append(created)
        return created
    }

    func assignChore(choreId: String, memberId: String, due: Date?) async throws {
        let a = try await db.assignChore(choreId: choreId, memberId: memberId, due: due)
        assignments.append(a)
    }

    func completeChore(assignmentId: String, photoURL: String? = nil) async throws {
        let submittedBy = auth.currentUser?.id
        let saved = try await db.submitCompletion(assignmentId: assignmentId, submittedBy: submittedBy, photoURL: photoURL)
        completions.insert(saved, at: 0)
        pendingApprovals.insert(saved, at: 0)
    }

    func approveCompletion(_ completion: ChoreCompletion) async throws {
        guard let reviewer = auth.currentUser?.id else { return }
        let updated = try await db.reviewCompletion(id: completion.id, status: .approved, reviewedBy: reviewer)
        replaceCompletion(updated)
    }

    func rejectCompletion(_ completion: ChoreCompletion) async throws {
        guard let reviewer = auth.currentUser?.id else { return }
        let updated = try await db.reviewCompletion(id: completion.id, status: .rejected, reviewedBy: reviewer)
        replaceCompletion(updated)
    }

    private func replaceCompletion(_ updated: ChoreCompletion) {
        if let i = completions.firstIndex(where: { $0.id == updated.id }) { completions[i] = updated }
        pendingApprovals.removeAll { $0.id == updated.id || updated.status != .pending }
        if updated.status == .pending { pendingApprovals.append(updated) }
    }
}
```

## File: ContentView.swift

```swift

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var familyService: FamilyService
    @EnvironmentObject var choreService: ChoreService
    @EnvironmentObject var rewardsService: RewardsService

    var body: some View {
        Group {
            if auth.isAuthenticated, let user = auth.currentUser {
                MainShell(user: user)
                    .task {
                        await familyService.ensureFamilyExists()
                        if let famId = familyService.family?.id ?? user.familyId {
                            await familyService.loadMembers()
                            await choreService.loadAll(for: famId)
                            await rewardsService.loadAll(familyId: famId)
                        }
                    }
            } else if auth.pendingVerificationEmail != nil {
                EmailVerificationView()
            } else {
                AuthenticationView()
            }
        }
    }
}

struct MainShell: View {
    let user: AppUser
    @EnvironmentObject var familyService: FamilyService

    var body: some View {
        TabView {
            ParentDashboardView()
                .tabItem { Label("Dashboard", systemImage: "house") }
            ChoresScreen()
                .tabItem { Label("Chores", systemImage: "checkmark.circle") }
            RewardsScreen()
                .tabItem { Label("Rewards", systemImage: "gift") }
            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}

struct ChoresScreen: View {
    @EnvironmentObject var chores: ChoreService
    @EnvironmentObject var family: FamilyService
    @State private var newTitle = ""
    @State private var points = 5

    var body: some View {
        NavigationView {
            VStack {
                List(chores.chores, id: \ .id) { c in
                    VStack(alignment: .leading) {
                        Text(c.title).font(.headline)
                        Text("\(c.points) pts").font(.subheadline)
                    }
                }
                .listStyle(.plain)

                HStack {
                    TextField("New chore title", text: $newTitle).textFieldStyle(.roundedBorder)
                    Stepper("\(points) pts", value: $points, in: 1...50)
                    Button("Add") {
                        Task {
                            if let famId = family.family?.id {
                                _ = try? await chores.createChore(familyId: famId, title: newTitle, description: nil, points: points, requirePhoto: false, recurrence: nil)
                                await chores.loadChores(familyId: famId)
                                newTitle = ""
                            }
                        }
                    }.buttonStyle(.borderedProminent)
                }.padding()
            }
            .navigationTitle("Chores")
        }
    }
}

struct RewardsScreen: View {
    @EnvironmentObject var rewards: RewardsService
    @EnvironmentObject var family: FamilyService
    @State private var name = ""
    @State private var cost = 10

    var body: some View {
        NavigationView {
            VStack {
                List(rewards.rewards, id: \ .id) { r in
                    HStack {
                        Text(r.name).font(.headline)
                        Spacer()
                        Text("\(r.costPoints) pts")
                    }
                }.listStyle(.plain)

                HStack {
                    TextField("Reward name", text: $name).textFieldStyle(.roundedBorder)
                    Stepper("\(cost) pts", value: $cost, in: 1...500)
                    Button("Add") {
                        Task {
                            if let famId = family.family?.id {
                                try? await rewards.createReward(familyId: famId, name: name, costPoints: cost)
                                await rewards.loadRewards(familyId: famId)
                                name = ""
                            }
                        }
                    }.buttonStyle(.borderedProminent)
                }.padding()
            }
            .navigationTitle("Rewards")
        }
    }
}

struct SettingsScreen: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var family: FamilyService
    @State private var childName = ""
    @State private var childAge: Int = 10

    var body: some View {
        Form {
            Section("Family") {
                Text(family.family?.name ?? "—")
                Button("Add Child") {
                    Task { try? await family.addChild(childName, age: childAge); await family.loadMembers() }
                }
                HStack {
                    TextField("Name", text: $childName)
                    Stepper("Age: \(childAge)", value: $childAge, in: 3...18)
                }
            }
            Section("Account") {
                Button("Sign out") { Task { await auth.signOut() } }.foregroundColor(.red)
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
    @EnvironmentObject var choreService: ChoreService
    @EnvironmentObject var rewardsService: RewardsService

    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        NavigationView {
            List {
                if let error {
                    Text(error).foregroundColor(.red)
                }

                Section("Family") {
                    Text("Family ID")
                    Spacer()
                    Text(authService.currentUser?.familyId ?? "None")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Actions") {
                    Button {
                        Task { await refresh() }
                    } label: {
                        if isLoading {
                            ProgressView().progressViewStyle(.circular)
                        } else {
                            Text("Refresh Data")
                        }
                    }
                }
            }
            .navigationTitle("Dashboard")
            .task { await refresh() }
        }
    }

    private func refresh() async {
        isLoading = true
        defer { isLoading = false }

        guard let familyId = authService.currentUser?.familyId else {
            self.error = "No family selected"
            return
        }

        // These service APIs expect a familyId
        await choreService.loadAll(for: familyId)
        await rewardsService.loadAll(familyId: familyId)
    }
}
```

## File: DatabaseAPI.swift

```swift

// DatabaseAPI.swift — fixed generics + AnyEncodable payloads
import Foundation
import Supabase

struct DatabaseAPI {
    static let shared = DatabaseAPI()
    private let client = AppSupabase.shared.client
    private init() {}

    // MARK: - Profiles & Roles

    struct UserRoleInfo: Codable {
        let familyId: String?
        let userId: String?
        let role: UserRole
        enum CodingKeys: String, CodingKey {
            case familyId = "family_id"
            case userId = "user_id"
            case role
        }
    }

    func fetchProfile(userId: String) async throws -> Profile? {
        let rows: [Profile] = try await client
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    func fetchUserRole(userId: String) async throws -> (familyId: String?, role: UserRole)? {
        let rows: [UserRoleInfo] = try await client
            .from("v_user_family_roles")
            .select()
            .eq("user_id", value: userId)
            .limit(1)
            .execute()
            .value
        if let r = rows.first { return (r.familyId, r.role) }
        if let fam = try await fetchFamilyByOwner(ownerId: userId) { return (fam.id, .parent) }
        return nil
    }

    // MARK: - Families

    func createFamily(name: String, ownerId: String) async throws -> Family {
        let payload: [String: AnyEncodable] = [
            "name": AnyEncodable(name),
            "owner_id": AnyEncodable(ownerId)
        ]
        let row: Family = try await client
            .from("families")
            .insert(payload, returning: .representation)
            .select()
            .single()
            .execute()
            .value
        return row
    }

    func fetchFamilyByOwner(ownerId: String) async throws -> Family? {
        let rows: [Family] = try await client
            .from("families")
            .select()
            .eq("owner_id", value: ownerId)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    func fetchFamily(id: String) async throws -> Family? {
        let rows: [Family] = try await client
            .from("families")
            .select()
            .eq("id", value: id)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    // MARK: - Family Members

    func listFamilyMembers(familyId: String, role: UserRole? = nil) async throws -> [FamilyMember] {
        var query = client.from("family_members").select().eq("family_id", value: familyId)
        if let role { query = query.eq("role", value: role.rawValue) }
        let rows: [FamilyMember] = try await query.order("created_at", ascending: true).execute().value
        return rows
    }

    func createChildMember(familyId: String, childName: String, age: Int?) async throws -> FamilyMember {
        var payload: [String: AnyEncodable] = [
            "family_id": AnyEncodable(familyId),
            "child_name": AnyEncodable(childName),
            "role": AnyEncodable(UserRole.child.rawValue)
        ]
        if let age { payload["age"] = AnyEncodable(age) }
        let row: FamilyMember = try await client
            .from("family_members")
            .insert(payload, returning: .representation)
            .select()
            .single()
            .execute()
            .value
        return row
    }

    // MARK: - Children (optional)

    func createChildProfile(parentUserId: String, name: String, birthdate: Date? = nil, avatarURL: String? = nil) async throws -> Child {
        var payload: [String: AnyEncodable] = [
            "parent_user_id": AnyEncodable(parentUserId),
            "name": AnyEncodable(name)
        ]
        if let birthdate {
            let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
            payload["birthdate"] = AnyEncodable(df.string(from: birthdate))
        }
        if let avatarURL { payload["avatar_url"] = AnyEncodable(avatarURL) }
        let row: Child = try await client
            .from("children")
            .insert(payload, returning: .representation)
            .select()
            .single()
            .execute()
            .value
        return row
    }

    func listChildrenOfParent(parentUserId: String) async throws -> [Child] {
        let rows: [Child] = try await client
            .from("children")
            .select()
            .eq("parent_user_id", value: parentUserId)
            .order("created_at", ascending: true)
            .execute()
            .value
        return rows
    }

    // MARK: - Chores

    func fetchChores(familyId: String) async throws -> [Chore] {
        let rows: [Chore] = try await client
            .from("chores")
            .select()
            .eq("family_id", value: familyId)
            .order("created_at", ascending: true)
            .execute()
            .value
        return rows
    }

    func createChore(familyId: String, title: String, description: String?, points: Int, requirePhoto: Bool, recurrence: String?, parentUserId: String) async throws -> Chore {
        var payload: [String: AnyEncodable] = [
            "family_id": AnyEncodable(familyId),
            "title": AnyEncodable(title),
            "points": AnyEncodable(points),
            "require_photo": AnyEncodable(requirePhoto),
            "parent_user_id": AnyEncodable(parentUserId)
        ]
        if let description { payload["description"] = AnyEncodable(description) }
        if let recurrence { payload["recurrence"] = AnyEncodable(recurrence) }
        let row: Chore = try await client
            .from("chores")
            .insert(payload, returning: .representation)
            .select()
            .single()
            .execute()
            .value
        return row
    }

    // MARK: - Assignments

    private func dateOnly(_ d: Date) -> String {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .iso8601)
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: d)
    }

    func assignChore(choreId: String, memberId: String, due: Date?) async throws -> ChoreAssignment {
        var payload: [String: AnyEncodable] = [
            "chore_id": AnyEncodable(choreId),
            "member_id": AnyEncodable(memberId)
        ]
        if let due { payload["due_date"] = AnyEncodable(dateOnly(due)) }
        let row: ChoreAssignment = try await client
            .from("chore_assignments")
            .insert(payload, returning: .representation)
            .select()
            .single()
            .execute()
            .value
        return row
    }

    func fetchAssignmentsForFamily(familyId: String) async throws -> [ChoreAssignment] {
        let members = try await listFamilyMembers(familyId: familyId)
        let memberIds = members.map { $0.id }
        if memberIds.isEmpty { return [] }
        let rows: [ChoreAssignment] = try await client
            .from("chore_assignments")
            .select()
            .in("member_id", values: memberIds)
            .order("created_at", ascending: false)
            .execute()
            .value
        return rows
    }

    // MARK: - Completions

    func submitCompletion(assignmentId: String, submittedBy: String?, photoURL: String?) async throws -> ChoreCompletion {
        var payload: [String: AnyEncodable] = [
            "assignment_id": AnyEncodable(assignmentId),
            "status": AnyEncodable(CompletionStatus.pending.rawValue)
        ]
        if let submittedBy { payload["submitted_by"] = AnyEncodable(submittedBy) }
        if let photoURL { payload["photo_url"] = AnyEncodable(photoURL) }
        let row: ChoreCompletion = try await client
            .from("chore_completions")
            .insert(payload, returning: .representation)
            .select()
            .single()
            .execute()
            .value
        return row
    }

    func reviewCompletion(id: String, status: CompletionStatus, reviewedBy: String) async throws -> ChoreCompletion {
        let payload: [String: AnyEncodable] = [
            "status": AnyEncodable(status.rawValue),
            "reviewed_by": AnyEncodable(reviewedBy),
            "reviewed_at": AnyEncodable(ISO8601DateFormatter().string(from: Date()))
        ]
        let row: ChoreCompletion = try await client
            .from("chore_completions")
            .update(payload, returning: .representation)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
        return row
    }

    func fetchCompletionsForFamily(familyId: String) async throws -> [ChoreCompletion] {
        let assignments = try await fetchAssignmentsForFamily(familyId: familyId)
        let ids = assignments.map { $0.id }
        if ids.isEmpty { return [] }
        let rows: [ChoreCompletion] = try await client
            .from("chore_completions")
            .select()
            .in("assignment_id", values: ids)
            .order("completed_at", ascending: false)
            .execute()
            .value
        return rows
    }

    // MARK: - Rewards & Redemptions

    func fetchRewards(familyId: String) async throws -> [Reward] {
        let rows: [Reward] = try await client
            .from("rewards")
            .select()
            .eq("family_id", value: familyId)
            .order("created_at", ascending: true)
            .execute()
            .value
        return rows
    }

    func createReward(familyId: String, name: String, costPoints: Int) async throws -> Reward {
        let payload: [String: AnyEncodable] = [
            "family_id": AnyEncodable(familyId),
            "name": AnyEncodable(name),
            "cost_points": AnyEncodable(costPoints)
        ]
        let row: Reward = try await client
            .from("rewards")
            .insert(payload, returning: .representation)
            .select()
            .single()
            .execute()
            .value
        return row
    }

    func updateReward(reward: Reward) async throws -> Reward {
        let row: Reward = try await client
            .from("rewards")
            .update(reward, returning: .representation)
            .eq("id", value: reward.id)
            .select()
            .single()
            .execute()
            .value
        return row
    }

    func deleteReward(id: String) async throws {
        _ = try await client
            .from("rewards")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    func requestRedemption(rewardId: String, memberId: String) async throws -> RewardRedemption {
        let payload: [String: AnyEncodable] = [
            "reward_id": AnyEncodable(rewardId),
            "member_id": AnyEncodable(memberId)
        ]
        let row: RewardRedemption = try await client
            .from("reward_redemptions")
            .insert(payload, returning: .representation)
            .select()
            .single()
            .execute()
            .value
        return row
    }

    func fetchRedemptionsForFamily(familyId: String) async throws -> [RewardRedemption] {
        let members = try await listFamilyMembers(familyId: familyId)
        let ids = members.map { $0.id }
        if ids.isEmpty { return [] }
        let rows: [RewardRedemption] = try await client
            .from("reward_redemptions")
            .select()
            .in("member_id", values: ids)
            .order("requested_at", ascending: false)
            .execute()
            .value
        return rows
    }

    func setRedemptionStatus(id: String, status: RedemptionStatus, decidedBy: String) async throws -> RewardRedemption {
        let payload: [String: AnyEncodable] = [
            "status": AnyEncodable(status.rawValue),
            "decided_by": AnyEncodable(decidedBy),
            "decided_at": AnyEncodable(ISO8601DateFormatter().string(from: Date()))
        ]
        let row: RewardRedemption = try await client
            .from("reward_redemptions")
            .update(payload, returning: .representation)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
        return row
    }

    // MARK: - Points Ledger

    func fetchLedger(familyId: String, memberId: String? = nil) async throws -> [PointsLedger] {
        var q = client.from("points_ledger").select().eq("family_id", value: familyId)
        if let memberId { q = q.eq("member_id", value: memberId) }
        let rows: [PointsLedger] = try await q.order("created_at", ascending: false).execute().value
        return rows
    }

    func addLedgerEntry(_ entry: PointsLedger) async throws -> PointsLedger {
        let row: PointsLedger = try await client
            .from("points_ledger")
            .insert(entry, returning: .representation)
            .select()
            .single()
            .execute()
            .value
        return row
    }
}
```

## File: EmailVerificationView.swift

```swift

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
```

## File: FamilyService.swift

```swift

import Foundation
import Combine

@MainActor
final class FamilyService: ObservableObject {
    static let shared = FamilyService()

    @Published private(set) var family: Family?
    @Published private(set) var members: [FamilyMember] = []

    private let auth = AuthService.shared
    private let db = DatabaseAPI.shared
    private init() {}

    func ensureFamilyExists(named defaultName: String = "My Family") async {
        guard let userId = auth.currentUser?.id else { return }
        do {
            if let fam = try await db.fetchFamilyByOwner(ownerId: userId) {
                self.family = fam
            } else {
                self.family = try await db.createFamily(name: defaultName, ownerId: userId)
            }
        } catch {
            print("ensureFamilyExists error:", error)
        }
    }

    func loadMembers() async {
        guard let familyId = family?.id ?? auth.currentUser?.familyId else { return }
        do { members = try await db.listFamilyMembers(familyId: familyId) } catch { print(error) }
    }

    func addChild(_ name: String, age: Int?) async throws {
        guard let familyId = family?.id ?? auth.currentUser?.familyId else { return }
        let created = try await db.createChildMember(familyId: familyId, childName: name, age: age)
        members.append(created)
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
    case parent, child
}

public enum CompletionStatus: String, Codable, CaseIterable {
    case pending, approved, rejected
}

public enum RedemptionStatus: String, Codable, CaseIterable {
    case requested, approved, rejected
}

// MARK: - Users

public struct AppUser: Identifiable, Codable, Equatable {
    public var id: String                   // auth user id
    public var email: String?
    public var role: UserRole               // from v_user_family_roles or default .parent
    public var familyId: String?            // fetched via families.owner_id or v_user_family_roles
}

// MARK: - Profiles (DB: profiles)

public struct Profile: Identifiable, Codable, Equatable {
    public var id: String                   // equals auth user id
    public var displayName: String?
    public var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case createdAt = "created_at"
    }
}

// MARK: - Families (DB: families)

public struct Family: Identifiable, Codable, Equatable {
    public var id: String
    public var ownerId: String
    public var name: String
    public var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case ownerId = "owner_id"
        case name
        case createdAt = "created_at"
    }
}

// MARK: - Family Members (DB: family_members)

public struct FamilyMember: Identifiable, Codable, Equatable {
    public var id: String
    public var familyId: String
    public var userId: String?
    public var childName: String?
    public var age: Int?
    public var role: UserRole
    public var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case userId = "user_id"
        case childName = "child_name"
        case age
        case role
        case createdAt = "created_at"
    }
}

// MARK: - Children (DB: children) — optional profile table for kids without accounts

public struct Child: Identifiable, Codable, Equatable {
    public var id: String
    public var parentUserId: String
    public var name: String
    public var birthdate: Date?
    public var avatarURL: String?
    public var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case parentUserId = "parent_user_id"
        case name
        case birthdate
        case avatarURL = "avatar_url"
        case createdAt = "created_at"
    }
}

// MARK: - Chores (DB: chores)

public struct Chore: Identifiable, Codable, Equatable {
    public var id: String
    public var familyId: String
    public var title: String
    public var description: String?
    public var points: Int
    public var requirePhoto: Bool
    public var recurrence: String?
    public var parentUserId: String
    public var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case title
        case description
        case points
        case requirePhoto = "require_photo"
        case recurrence
        case parentUserId = "parent_user_id"
        case createdAt = "created_at"
    }
}

// MARK: - Chore Assignments (DB: chore_assignments)

public struct ChoreAssignment: Identifiable, Codable, Equatable {
    public var id: String
    public var choreId: String
    public var memberId: String
    public var dueDate: String?            // DB is 'date' (YYYY-MM-DD)

    public var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case choreId = "chore_id"
        case memberId = "member_id"
        case dueDate = "due_date"
        case createdAt = "created_at"
    }

    public var dueDateAsDate: Date? {
        guard let dueDate else { return nil }
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .iso8601)
        df.dateFormat = "yyyy-MM-dd"
        return df.date(from: dueDate)
    }
}

// MARK: - Completions (DB: chore_completions)

public struct ChoreCompletion: Identifiable, Codable, Equatable {
    public var id: String
    public var assignmentId: String
    public var submittedBy: String?
    public var photoURL: String?
    public var status: CompletionStatus
    public var completedAt: Date?
    public var reviewedBy: String?
    public var reviewedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case assignmentId = "assignment_id"
        case submittedBy = "submitted_by"
        case photoURL = "photo_url"
        case status
        case completedAt = "completed_at"
        case reviewedBy = "reviewed_by"
        case reviewedAt = "reviewed_at"
    }
}

// MARK: - Rewards (DB: rewards)

public struct Reward: Identifiable, Codable, Equatable {
    public var id: String
    public var familyId: String
    public var name: String
    public var costPoints: Int
    public var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case name
        case costPoints = "cost_points"
        case createdAt = "created_at"
    }
}

// MARK: - Reward Redemptions (DB: reward_redemptions)

public struct RewardRedemption: Identifiable, Codable, Equatable {
    public var id: String
    public var rewardId: String
    public var memberId: String
    public var status: RedemptionStatus
    public var requestedAt: Date?
    public var decidedBy: String?
    public var decidedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case rewardId = "reward_id"
        case memberId = "member_id"
        case status
        case requestedAt = "requested_at"
        case decidedBy = "decided_by"
        case decidedAt = "decided_at"
    }
}

// MARK: - Points Ledger (DB: points_ledger)

public struct PointsLedger: Identifiable, Codable, Equatable {
    public var id: String
    public var familyId: String
    public var memberId: String
    public var delta: Int
    public var reason: String?
    public var event: String               // e.g., 'chore_completed', 'reward_redeemed'
    public var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case memberId = "member_id"
        case delta
        case reason
        case event
        case createdAt = "created_at"
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
    @EnvironmentObject var family: FamilyService
    @EnvironmentObject var chores: ChoreService
    @EnvironmentObject var rewards: RewardsService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Family").font(.headline)
                Text(family.family?.name ?? "—")
                Divider()
                Text("Members").font(.headline)
                ForEach(family.members, id: \ .id) { m in
                    HStack {
                        Text(m.childName ?? (m.userId ?? "Member"))
                        Spacer()
                        Text(m.role.rawValue.capitalized)
                    }
                    .padding(.vertical, 4)
                }
                Divider()
                Text("Chores: \(chores.chores.count) • Rewards: \(rewards.rewards.count)")
            }
            .padding()
        }
        .navigationTitle("Dashboard")
    }
}
```

## File: ParentSheets.swift

```swift
import SwiftUI

// MARK: - Add Child

struct AddChildView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService

    @State private var name = ""
    @State private var hasBirthdate = false
    @State private var birthdateValue = Date()
    @State private var pin = ""               // kept for UI; not sent to DB

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

                    TextField("4-digit PIN (optional)", text: $pin)
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
        guard let familyId = authService.currentUser?.familyId,
              let parentId = authService.currentUser?.id else {
            self.error = "Missing family or user context"
            return
        }

        do {
            // Prefer the canonical family_members entry for a child
            _ = try await DatabaseAPI.shared.createChildMember(
                familyId: familyId,
                childName: name.trimmingCharacters(in: .whitespaces),
                age: nil
            )

            // Optional: also create a child profile record if you’re using that table
            // _ = try await DatabaseAPI.shared.createChildProfile(
            //     parentUserId: parentId,
            //     name: name.trimmingCharacters(in: .whitespaces),
            //     birthdate: hasBirthdate ? birthdateValue : nil,
            //     avatarURL: nil
            // )

            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Add Chore

private struct SelectableChild: Identifiable, Hashable {
    let id: String
    let name: String
}

struct AddChoreView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService

    @State private var title = ""
    @State private var description = ""
    @State private var points = 10
    @State private var requirePhoto = false

    @State private var children: [SelectableChild] = []
    @State private var selected: Set<String> = []

    @State private var error: String?
    @State private var isSaving = false
    @State private var isLoadingKids = false

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
                    if isLoadingKids {
                        ProgressView().progressViewStyle(.circular)
                    } else if children.isEmpty {
                        Text("No children yet").foregroundColor(.secondary)
                    } else {
                        ForEach(children) { child in
                            Toggle(isOn: Binding(
                                get: { selected.contains(child.id) },
                                set: { isOn in
                                    if isOn { selected.insert(child.id) }
                                    else { selected.remove(child.id) }
                                })
                            ) {
                                Text(child.name)
                            }
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
            .task { await loadChildren() }
        }
    }

    private func loadChildren() async {
        guard let familyId = authService.currentUser?.familyId else { return }
        isLoadingKids = true
        defer { isLoadingKids = false }
        do {
            // Pull family members with child role
            let members = try await DatabaseAPI.shared.listFamilyMembers(
                familyId: familyId,
                role: .child
            )
            self.children = members.map {
                // Try common name keys; fall back to id
                SelectableChild(id: $0.id, name: ($0.name ?? $0.childName ?? "Child \($0.id.prefix(4))"))
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func save() async {
        guard let familyId = authService.currentUser?.familyId,
              let parentId = authService.currentUser?.id else {
            self.error = "Missing family or user context"
            return
        }

        isSaving = true; defer { isSaving = false }

        do {
            // Create chore
            let chore = try await DatabaseAPI.shared.createChore(
                familyId: familyId,
                title: title.trimmingCharacters(in: .whitespaces),
                description: description.isEmpty ? nil : description,
                points: points,
                requirePhoto: requirePhoto,
                recurrence: nil,
                parentUserId: parentId
            )

            // Assign to selected members
            for childId in selected {
                _ = try await DatabaseAPI.shared.assignChore(
                    choreId: chore.id,
                    memberId: childId,
                    due: nil
                )
            }

            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Add Reward

struct AddRewardView: View {
    @Environment(\.dismiss) private var dismiss
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
        guard let familyId = authService.currentUser?.familyId else { return }
        isSaving = true; defer { isSaving = false }
        do {
            _ = try await DatabaseAPI.shared.createReward(
                familyId: familyId,
                name: name.trimmingCharacters(in: .whitespaces),
                costPoints: cost
            )
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Approvals

struct ApprovalsView: View {
    @EnvironmentObject var authService: AuthService

    @State private var items: [ChoreCompletion] = []
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        List {
            if let error { Text(error).foregroundColor(.red) }

            if items.isEmpty && !isLoading {
                Text("Nothing to approve right now").foregroundColor(.secondary)
            }

            ForEach(items) { c in
                ApprovalRow(completion: c) { action in
                    Task { await act(on: c, action: action) }
                }
            }
        }
        .navigationTitle("Approvals")
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        guard let familyId = authService.currentUser?.familyId else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let all = try await DatabaseAPI.shared.fetchCompletionsForFamily(familyId: familyId)
            // Keep only pending
            self.items = all.filter { $0.status == .pending }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func act(on c: ChoreCompletion, action: ApprovalAction) async {
        guard let reviewer = authService.currentUser?.id else { return }
        do {
            let newStatus: CompletionStatus = (action == .approve) ? .approved : .rejected
            _ = try await DatabaseAPI.shared.reviewCompletion(
                id: c.id,
                status: newStatus,
                reviewedBy: reviewer
            )
            await load()
        } catch {
            self.error = error.localizedDescription
        }
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
    @Published private(set) var points: [PointsLedger] = []

    private let auth = AuthService.shared
    private let db = DatabaseAPI.shared
    private init() {}

    func loadAll(familyId: String) async {
        async let a = loadRewards(familyId: familyId)
        async let b = loadRedemptions(familyId: familyId)
        _ = await (a, b)
    }

    func loadRewards(familyId: String) async {
        do { rewards = try await db.fetchRewards(familyId: familyId) } catch { print(error) }
    }

    func loadRedemptions(familyId: String) async {
        do { redemptions = try await db.fetchRedemptionsForFamily(familyId: familyId) } catch { print(error) }
    }

    func loadPointsFor(memberId: String) async {
        guard let familyId = auth.currentUser?.familyId ?? FamilyService.shared.family?.id else { return }
        do { points = try await db.fetchLedger(familyId: familyId, memberId: memberId) } catch { print(error) }
    }

    func createReward(familyId: String, name: String, costPoints: Int) async throws {
        let created = try await db.createReward(familyId: familyId, name: name, costPoints: costPoints)
        rewards.append(created)
    }

    func updateReward(_ reward: Reward) async throws {
        let updated = try await db.updateReward(reward: reward)
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

    func decide(_ redemption: RewardRedemption, approve: Bool) async throws {
        guard let decider = auth.currentUser?.id else { return }
        let status: RedemptionStatus = approve ? .approved : .rejected
        let updated = try await db.setRedemptionStatus(id: redemption.id, status: status, decidedBy: decider)
        if let i = redemptions.firstIndex(where: { $0.id == updated.id }) { redemptions[i] = updated }

        if approve,
           let familyId = auth.currentUser?.familyId ?? FamilyService.shared.family?.id,
           let reward = rewards.first(where: { $0.id == redemption.rewardId }) {
            let entry = PointsLedger(id: UUID().uuidString, familyId: familyId, memberId: redemption.memberId, delta: -reward.costPoints, reason: "Redeemed: \(reward.name)", event: "reward_redeemed", createdAt: nil)
            _ = try await db.addLedgerEntry(entry)
        }
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

struct StorageAPI {
    static let shared = StorageAPI()
    private let client = AppSupabase.shared.client
    private init() {}

    func publicURL(bucket: String, path: String) -> URL? {
        // Some SDK versions mark this as `throws`; keep it safe.
        return try? client.storage.from(bucket).getPublicURL(path: path)
    }
}
```

