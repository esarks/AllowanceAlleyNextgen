# Swift Sources

_Generated on Fri Aug 22 10:07:58 EDT 2025 from directory: ._

## File: AddChildView.swift

```swift
import SwiftUI

struct AddChildView: View { var body: some View { Text("Add Child") } }```

## File: AddChoreView.swift

```swift
import SwiftUI

struct AddChoreView: View { var body: some View { Text("Add Chore") } }```

## File: AddRewardView.swift

```swift

import SwiftUI

struct AddRewardView: View {
    @EnvironmentObject var rewardsService: RewardsService
    @EnvironmentObject var authService: AuthService

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var costPoints = 50
    @State private var error: String?

    var body: some View {
        NavigationView {
            Form {
                Section("Reward Details") {
                    TextField("Reward name", text: $name)

                    HStack {
                        Text("Cost in points")
                        Spacer()
                        Stepper("\(costPoints)", value: $costPoints, in: 1...1000, step: 10)
                    }
                }

                Section("Examples") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Low cost (10-50 points):")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("Extra screen time, choose snack, stay up 15 min late")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Medium cost (50-150 points):")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("Choose dinner, friend sleepover, special outing")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("High cost (150+ points):")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("New toy, movie theater trip, special purchase")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let error {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("Add Reward")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveReward()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func saveReward() {
        guard let familyId = authService.currentUser?.familyId ?? authService.currentUser?.id else {
            error = "Authentication error"
            return
        }

        let reward = Reward(
            familyId: familyId,
            name: name,
            costPoints: costPoints
        )

        Task {
            do {
                try await rewardsService.createReward(reward)
                dismiss()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}
```

## File: AdditionalViews.swift

```swift
import SwiftUI

struct ReportsView: View {
    var body: some View {
        Text("Reports")
    }
}

struct ParentSettingsView: View {
    var body: some View {
        Text("Parent Settings")
    }
}

struct ChildDashboardView: View {
    let childId: String
    var body: some View {
        Text("Child Dashboard for \(childId)")
    }
}

struct RewardsView: View {
    let childId: String
    var body: some View {
        Text("Rewards for \(childId)")
    }
}

struct ChildSettingsView: View {
    let childId: String
    var body: some View {
        Text("Child Settings for \(childId)")
    }
}
```

## File: AllowanceAlleyApp.swift

```swift
import SwiftUI
import Combine

@main
struct AllowanceAlleyApp: App {
    @StateObject private var authService = AuthService.shared
    @StateObject private var familyService = FamilyService.shared
    @StateObject private var choreService = ChoreService.shared
    @StateObject private var rewardsService = RewardsService.shared
    @StateObject private var notificationsService = NotificationsService.shared
    @StateObject private var imageStore = ImageStore.shared
    
    private let coreDataStack = CoreDataStack.shared
    private let supabase = AppSupabase.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authService)
                .environmentObject(familyService)
                .environmentObject(choreService)
                .environmentObject(rewardsService)
                .environmentObject(notificationsService)
                .environmentObject(imageStore)
                .onAppear {
                    setupServices()
                }
        }
    }
    
    private func setupServices() {
        Task {
            await authService.resetAuthenticationState()
            authService.initialize()
        }
        _ = coreDataStack
        _ = supabase
    }
}
```

## File: AppConfig.swift

```swift
import Foundation
import CoreGraphics

enum VerificationMode {
    case inlineCode   // show 6-digit code on screen (dev)
    case emailLink    // real email verification (prod)
}

struct AppConfig {
    static let supabaseURL: String = {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              !url.isEmpty else { fatalError("SUPABASE_URL not found in Info.plist") }
        return url
    }()

    static let supabaseAnonKey: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              !key.isEmpty else { fatalError("SUPABASE_ANON_KEY not found in Info.plist") }
        return key
    }()

    // 👇 flip to .emailLink in prod
    static let verificationMode: VerificationMode = .inlineCode

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
        self.client = SupabaseClient(supabaseURL: url, supabaseKey: AppConfig.supabaseAnonKey)
    }
}
```

## File: ApprovalsView.swift

```swift

import SwiftUI

struct ApprovalsView: View {
    @EnvironmentObject var choreService: ChoreService
    @EnvironmentObject var rewardsService: RewardsService
    @EnvironmentObject var familyService: FamilyService

    var body: some View {
        NavigationView {
            List {
                Section("Chore Completions") {
                    if choreService.pendingApprovals.isEmpty {
                        Text("No pending chore approvals")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(choreService.pendingApprovals) { completion in
                            ChoreCompletionRow(completion: completion)
                        }
                    }
                }

                Section("Reward Requests") {
                    let pendingRedemptions = rewardsService.getPendingRedemptions()
                    if pendingRedemptions.isEmpty {
                        Text("No pending reward requests")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(pendingRedemptions) { redemption in
                            RewardRedemptionRow(redemption: redemption)
                        }
                    }
                }
            }
            .navigationTitle("Approvals")
            .task {
                try? await choreService.loadCompletions()
                try? await rewardsService.loadRedemptions()
            }
        }
    }
}

struct ChoreCompletionRow: View {
    let completion: ChoreCompletion
    @EnvironmentObject var choreService: ChoreService
    @EnvironmentObject var familyService: FamilyService

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Chore Completed")
                    .font(.headline)
                Spacer()
                if let completedAt = completion.completedAt {
                    Text(completedAt, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let submittedBy = completion.submittedBy {
                let childName = familyService.children.first { $0.id == submittedBy }?.name ?? "Unknown"
                Text("By: \(childName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if completion.photoURL != nil {
                Label("Photo included", systemImage: "camera.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
            }

            HStack {
                Button("Approve") {
                    Task {
                        try? await choreService.approveCompletion(completion)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                Button("Reject") {
                    Task {
                        try? await choreService.rejectCompletion(completion)
                    }
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

struct RewardRedemptionRow: View {
    let redemption: RewardRedemption
    @EnvironmentObject var rewardsService: RewardsService
    @EnvironmentObject var familyService: FamilyService

    private var rewardName: String {
        rewardsService.rewards.first { $0.id == redemption.rewardId }?.name ?? "Unknown Reward"
    }

    private var childName: String {
        familyService.children.first { $0.id == redemption.memberId }?.name ?? "Unknown Child"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(rewardName)
                    .font(.headline)
                Spacer()
                if let requestedAt = redemption.requestedAt {
                    Text(requestedAt, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text("Requested by: \(childName)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                Button("Approve") {
                    Task {
                        try? await rewardsService.approveRedemption(redemption)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                Button("Reject") {
                    Task {
                        try? await rewardsService.rejectRedemption(redemption)
                    }
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .padding(.vertical, 4)
    }
}
```

## File: AuthService+Verification.swift

```swift

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
```

## File: AuthService.swift

```swift
import Foundation
import Combine
import Supabase

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()
    @Published var isAuthenticated = false
    @Published var currentUser: AppUser?
    @Published var currentSupabaseUser: User?
    @Published var isEmailVerified = false
    @Published var pendingVerificationEmail: String?
    private let supabase = AppSupabase.shared
    private var authStateListener: Task<Void, Never>?
    private init() {}

    func initialize() {
        Task {
            await refreshSession()
            startAuthListener()
        }
    }
    func resetAuthenticationState() async { await signOutLocally() }
    deinit { authStateListener?.cancel() }

    func signUp(email: String, password: String, familyName: String) async throws {
        let response = try await supabase.client.auth.signUp(email: email, password: password)
        let user = response.user
        pendingVerificationEmail = email
        isEmailVerified = (user.emailConfirmedAt != nil)
        if isEmailVerified { try await createUserProfile(user: user, familyName: familyName) }
        else { currentSupabaseUser = user; isAuthenticated = false }
    }
    func signIn(email: String, password: String) async throws {
        let response = try await supabase.client.auth.signIn(email: email, password: password)
        let user = response.user
        await loadUserProfile(supabaseUser: user)
    }
    func signInChild(childId: String, pin: String) async throws {
        guard pin.count == 4, pin.allSatisfy(\.isNumber) else { throw AuthError.invalidPin }
        let child = AppUser(id: childId, role: .child, displayName: "Child User")
        currentUser = child; currentSupabaseUser = nil; isAuthenticated = true; isEmailVerified = true; pendingVerificationEmail = nil
    }
    func signOut() async throws { try await supabase.client.auth.signOut(); await signOutLocally() }

    private func refreshSession() async {
        do { let session = try await supabase.client.auth.session; await applySession(session) }
        catch { await signOutLocally() }
    }
    private func applySession(_ session: Session) async { await loadUserProfile(supabaseUser: session.user) }
    private func startAuthListener() {
        authStateListener?.cancel()
        authStateListener = Task { [weak self] in
            guard let self else { return }
            do { for try await _ in self.supabase.client.auth.authStateChanges { await self.refreshSession() } } catch {}
        }
    }
    private func signOutLocally() async {
        currentUser = nil; currentSupabaseUser = nil; isAuthenticated = false; isEmailVerified = false; pendingVerificationEmail = nil
    }
    private func createUserProfile(user: User, familyName: String) async throws {
        let family = Family(ownerId: user.id.uuidString, name: familyName)
        let createdFamily = try await DatabaseAPI.shared.createFamily(family)
        let appUser = AppUser(id: user.id.uuidString, role: .parent, email: user.email, displayName: "\(familyName) Parent", familyId: createdFamily.id)
        currentUser = appUser; currentSupabaseUser = user; isAuthenticated = true; pendingVerificationEmail = nil; isEmailVerified = (user.emailConfirmedAt != nil)
    }
    private func loadUserProfile(supabaseUser: User) async {
        let appUser = AppUser(id: supabaseUser.id.uuidString, role: .parent, email: supabaseUser.email, displayName: "Parent")
        currentUser = appUser; currentSupabaseUser = supabaseUser; isAuthenticated = true; isEmailVerified = (supabaseUser.emailConfirmedAt != nil); pendingVerificationEmail = nil
    }
}
enum AuthError: LocalizedError {
    case invalidPin, childNotFound
    var errorDescription: String? {
        switch self { case .invalidPin: return "Please enter a valid 4-digit PIN"; case .childNotFound: return "Child not found" }
    }
}```

## File: AuthenticationView.swift

```swift
import SwiftUI

struct AuthenticationView: View { var body: some View { Text("Login / Signup") } }```

## File: ChildChoresView.swift

```swift

import SwiftUI

struct ChildChoresView: View {
    let childId: String
    @EnvironmentObject var choreService: ChoreService
    @State private var assignments: [ChoreAssignment] = []
    @State private var completions: [ChoreCompletion] = []

    var body: some View {
        List {
            Section("To Do") {
                let pendingAssignments = assignments.filter { assignment in
                    !completions.contains { $0.assignmentId == assignment.id && $0.status != .rejected }
                }

                if pendingAssignments.isEmpty {
                    Text("No chores to do right now")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(pendingAssignments) { assignment in
                        ChildChoreRow(assignment: assignment, childId: childId)
                    }
                }
            }

            Section("Completed") {
                let completedAssignments = assignments.filter { assignment in
                    completions.contains { $0.assignmentId == assignment.id && $0.status == .approved }
                }

                if completedAssignments.isEmpty {
                    Text("No completed chores yet")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(completedAssignments) { assignment in
                        ChildChoreRow(assignment: assignment, childId: childId, isCompleted: true)
                    }
                }
            }

            Section("Pending Approval") {
                let pendingCompletions = completions.filter { $0.status == .pending && $0.submittedBy == childId }

                if pendingCompletions.isEmpty {
                    Text("No chores waiting for approval")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(pendingCompletions) { completion in
                        PendingChoreRow(completion: completion)
                    }
                }
            }
        }
        .navigationTitle("My Chores")
        .task {
            assignments = choreService.assignments.filter { $0.memberId == childId }
            completions = choreService.completions.filter { $0.submittedBy == childId }
        }
    }
}

struct ChildChoreRow: View {
    let assignment: ChoreAssignment
    let childId: String
    var isCompleted: Bool = false
    @EnvironmentObject var choreService: ChoreService
    @State private var isCompleting = false

    private var chore: Chore? {
        choreService.chores.first { $0.id == assignment.choreId }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(chore?.title ?? "Unknown Chore")
                    .font(.headline)
                    .strikethrough(isCompleted)
                    .foregroundColor(isCompleted ? .secondary : .primary)

                if let description = chore?.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                HStack {
                    if let dueDate = assignment.dueDate {
                        Text("Due: \(dueDate, style: .date)")
                            .font(.caption)
                            .foregroundColor(dueDate < Date() ? .red : .secondary)
                    }

                    if chore?.requirePhoto == true {
                        Label("Photo", systemImage: "camera.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }

                    Spacer()

                    if let points = chore?.points {
                        Text("\(points) pts")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
            }

            if !isCompleted {
                Button("Complete") {
                    isCompleting = true
                    Task {
                        try? await choreService.completeChore(assignment.id)
                        isCompleting = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isCompleting)
            }
        }
        .padding(.vertical, 4)
    }
}

struct PendingChoreRow: View {
    let completion: ChoreCompletion
    @EnvironmentObject var choreService: ChoreService

    private var assignment: ChoreAssignment? {
        choreService.assignments.first { $0.id == completion.assignmentId }
    }

    private var chore: Chore? {
        guard let assignment = assignment else { return nil }
        return choreService.chores.first { $0.id == assignment.choreId }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(chore?.title ?? "Unknown Chore")
                    .font(.headline)

                Text("Waiting for approval...")
                    .font(.caption)
                    .foregroundColor(.orange)

                if let completedAt = completion.completedAt {
                    Text("Submitted: \(completedAt, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "clock.fill")
                .foregroundColor(.orange)
        }
        .padding(.vertical, 4)
    }
}
```

## File: ChildHomeView.swift

```swift

import SwiftUI

struct ChildHomeView: View {
    let childId: String
    @EnvironmentObject var choreService: ChoreService
    @EnvironmentObject var rewardsService: RewardsService
    @State private var pointsBalance = 0
    @State private var todayAssignments: [ChoreAssignment] = []

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Points Display
                    VStack(spacing: 8) {
                        Text("My Points")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("\(pointsBalance)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(16)

                    // Today's Chores
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Today's Chores")
                                .font(.headline)
                            Spacer()
                            if !todayAssignments.isEmpty {
                                Text("\(todayAssignments.count)")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }

                        if todayAssignments.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.green)
                                Text("All done for today!")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 80)
                        } else {
                            ForEach(todayAssignments.prefix(3)) { assignment in
                                ChildChoreCard(assignment: assignment, childId: childId)
                            }

                            if todayAssignments.count > 3 {
                                NavigationLink("View all chores") {
                                    ChildChoresView(childId: childId)
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(16)

                    // Recent Activity
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Activity")
                            .font(.headline)

                        // Placeholder for recent points history
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text("Chore completed")
                                    .font(.subheadline)
                                Text("2 hours ago")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("+10 pts")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(16)
                }
                .padding()
            }
            .navigationTitle("Hi there! 👋")
            .task {
                await loadChildData()
            }
        }
    }

    private func loadChildData() async {
        todayAssignments = choreService.getTodayAssignments(for: childId)
        pointsBalance = await rewardsService.getPointsBalance(for: childId)
    }
}

struct ChildChoreCard: View {
    let assignment: ChoreAssignment
    let childId: String
    @EnvironmentObject var choreService: ChoreService
    @State private var isCompleting = false

    private var chore: Chore? {
        choreService.chores.first { $0.id == assignment.choreId }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(chore?.title ?? "Unknown Chore")
                    .font(.headline)

                if let description = chore?.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                HStack {
                    if chore?.requirePhoto == true {
                        Label("Photo needed", systemImage: "camera.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }

                    Spacer()

                    if let points = chore?.points {
                        Text("\(points) pts")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
            }

            Spacer()

            Button("Complete") {
                isCompleting = true
                Task {
                    try? await choreService.completeChore(assignment.id)
                    isCompleting = false
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isCompleting)
        }
        .padding()
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(12)
    }
}
```

## File: ChildMainView.swift

```swift
import SwiftUI

struct ChildMainView: View {
    let childId: String
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ChildDashboardView(childId: childId)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)
            ChildChoresView(childId: childId)
                .tabItem { Label("My Chores", systemImage: "list.bullet") }
                .tag(1)
            RewardsView(childId: childId)
                .tabItem { Label("Rewards", systemImage: "star.fill") }
                .tag(2)
            ChildSettingsView(childId: childId)
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(3)
        }
    }
}```

## File: ChildProfileView.swift

```swift

import SwiftUI

struct ChildProfileView: View {
    let childId: String
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var familyService: FamilyService
    @EnvironmentObject var rewardsService: RewardsService
    @State private var totalPoints = 0
    @State private var pointsHistory: [PointsLedger] = []

    private var child: Child? {
        familyService.children.first { $0.id == childId }
    }

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Circle()
                            .fill(Color.blue.gradient)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(child?.name.prefix(1) ?? "?")
                                    .font(.title)
                                    .foregroundColor(.white)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(child?.name ?? "Unknown")
                                .font(.title2)
                                .fontWeight(.semibold)

                            if let age = child?.age {
                                Text("Age \(age)")
                                    .foregroundColor(.secondary)
                            }

                            Text("\(totalPoints) total points earned")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

                Section("Points History") {
                    if pointsHistory.isEmpty {
                        Text("No points activity yet")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(pointsHistory.prefix(10)) { entry in
                            PointsHistoryRow(entry: entry)
                        }
                    }
                }

                Section {
                    Button("Sign Out") {
                        Task {
                            try? await authService.signOut()
                        }
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Profile")
            .task {
                totalPoints = await rewardsService.getPointsBalance(for: childId)
                pointsHistory = rewardsService.getPointsHistory(for: childId)
            }
        }
    }
}

struct PointsHistoryRow: View {
    let entry: PointsLedger

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.reason ?? "Points activity")
                    .font(.subheadline)

                Text(entry.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(entry.delta > 0 ? "+" : "")\(entry.delta)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(entry.delta > 0 ? .green : .red)
        }
    }
}
```

## File: ChildRewardsView.swift

```swift

import SwiftUI

struct ChildRewardsView: View {
    let childId: String
    @EnvironmentObject var rewardsService: RewardsService
    @State private var pointsBalance = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Points Header
                VStack(spacing: 8) {
                    Text("My Points")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("\(pointsBalance)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.blue)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))

                List {
                    Section("Available Rewards") {
                        if rewardsService.rewards.isEmpty {
                            Text("No rewards available yet")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            ForEach(rewardsService.rewards) { reward in
                                ChildRewardRow(reward: reward, childId: childId, canAfford: pointsBalance >= reward.costPoints)
                            }
                        }
                    }

                    Section("My Requests") {
                        let myRedemptions = rewardsService.redemptions.filter { $0.memberId == childId }

                        if myRedemptions.isEmpty {
                            Text("No reward requests yet")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            ForEach(myRedemptions) { redemption in
                                RedemptionStatusRow(redemption: redemption)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Rewards")
            .task {
                pointsBalance = await rewardsService.getPointsBalance(for: childId)
            }
        }
    }
}

struct ChildRewardRow: View {
    let reward: Reward
    let childId: String
    let canAfford: Bool
    @EnvironmentObject var rewardsService: RewardsService
    @State private var isRequesting = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(reward.name)
                    .font(.headline)
                    .foregroundColor(canAfford ? .primary : .secondary)

                Text("\(reward.costPoints) points")
                    .font(.subheadline)
                    .foregroundColor(canAfford ? .blue : .secondary)
            }

            Spacer()

            Button("Request") {
                isRequesting = true
                Task {
                    try? await rewardsService.requestRedemption(rewardId: reward.id, memberId: childId)
                    isRequesting = false
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canAfford || isRequesting)
        }
        .opacity(canAfford ? 1.0 : 0.6)
    }
}

struct RedemptionStatusRow: View {
    let redemption: RewardRedemption
    @EnvironmentObject var rewardsService: RewardsService

    private var rewardName: String {
        rewardsService.rewards.first { $0.id == redemption.rewardId }?.name ?? "Unknown Reward"
    }

    private var statusColor: Color {
        switch redemption.status {
        case .requested: return .orange
        case .approved: return .green
        case .rejected: return .red
        case .fulfilled: return .blue
        }
    }

    private var statusText: String {
        switch redemption.status {
        case .requested: return "Pending"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        case .fulfilled: return "Fulfilled"
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(rewardName)
                    .font(.headline)

                if let requestedAt = redemption.requestedAt {
                    Text("Requested: \(requestedAt, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text(statusText)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.2))
                .cornerRadius(8)
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
    
    @Published var chores: [Chore] = []
    @Published var assignments: [ChoreAssignment] = []
    @Published var completions: [ChoreCompletion] = []
    @Published var pendingApprovals: [ChoreCompletion] = []
    
    private let authService = AuthService.shared
    
    private init() {}
    
    func loadChores() async throws {
        guard let familyId = authService.currentUser?.familyId ?? authService.currentUser?.id else { return }
        chores = [
            Chore(familyId: familyId, title: "Make Bed", description: "Make your bed neatly every morning", points: 10, requirePhoto: false, parentUserId: authService.currentUser?.id ?? ""),
            Chore(familyId: familyId, title: "Take Out Trash", description: "Take the kitchen trash to the curb", points: 20, requirePhoto: true, parentUserId: authService.currentUser?.id ?? "")
        ]
    }
    
    func loadAssignments() async throws { assignments = [] }
    func loadCompletions() async throws {
        completions = []
        pendingApprovals = completions.filter { $0.status == .pending }
    }
    
    func createChore(_ chore: Chore, assignedTo childIds: [String]) async throws {
        chores.append(chore)
        for childId in childIds {
            let assignment = ChoreAssignment(choreId: chore.id, memberId: childId, dueDate: Date().adding(days: 1))
            assignments.append(assignment)
        }
    }
    
    func completeChore(_ assignmentId: String, photoURL: String? = nil) async throws {
        let completion = ChoreCompletion(assignmentId: assignmentId, submittedBy: authService.currentUser?.id, photoURL: photoURL, status: .pending, completedAt: Date())
        completions.append(completion)
        pendingApprovals.append(completion)
    }
    
    func approveCompletion(_ completion: ChoreCompletion) async throws {
        var updated = completion
        updated.status = .approved
        updated.reviewedBy = authService.currentUser?.id
        updated.reviewedAt = Date()
        if let index = completions.firstIndex(where: { $0.id == completion.id }) { completions[index] = updated }
        pendingApprovals.removeAll { $0.id == completion.id }
    }
    
    func rejectCompletion(_ completion: ChoreCompletion) async throws {
        var updated = completion
        updated.status = .rejected
        updated.reviewedBy = authService.currentUser?.id
        updated.reviewedAt = Date()
        if let index = completions.firstIndex(where: { $0.id == completion.id }) { completions[index] = updated }
        pendingApprovals.removeAll { $0.id == completion.id }
    }
    
    func getTodayAssignments(for childId: String) -> [ChoreAssignment] {
        assignments.filter { $0.memberId == childId && ($0.dueDate?.isToday ?? false) }
    }
    
    func getDashboardSummary() async -> DashboardSummary {
        var summary = DashboardSummary()
        summary.todayAssigned = assignments.filter { $0.dueDate?.isToday ?? false }.count
        summary.todayCompleted = completions.filter { $0.completedAt?.isToday ?? false }.count
        summary.thisWeekAssigned = assignments.filter { $0.dueDate?.isThisWeek ?? false }.count
        summary.thisWeekCompleted = completions.filter { $0.completedAt?.isThisWeek ?? false }.count
        summary.pendingApprovals = pendingApprovals.count
        return summary
    }
}
```

## File: ContentView.swift

```swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                if let user = authService.currentUser {
                    switch user.role {
                    case .parent:
                        ParentMainView()
                    case .child:
                        ChildMainView(childId: user.id)
                    }
                } else {
                    LoadingView(message: "Loading user profile...")
                }
            } else if authService.pendingVerificationEmail != nil {
                EmailVerificationView()
            } else {
                AuthenticationView()
            }
        }
    }
}

struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView().scaleEffect(1.5)
            Text(message).font(.subheadline).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
}```

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

    @State private var summary = DashboardSummary()
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if isLoading {
                        ProgressView("Loading dashboard...")
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        // Quick Stats Cards
                        HStack(spacing: 16) {
                            StatCard(title: "Today", completed: summary.todayCompleted, total: summary.todayAssigned, color: .blue)
                            StatCard(title: "This Week", completed: summary.thisWeekCompleted, total: summary.thisWeekAssigned, color: .green)
                        }

                        // Pending Approvals
                        if summary.pendingApprovals > 0 {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(.orange)
                                    Text("Pending Approvals")
                                        .font(.headline)
                                    Spacer()
                                    Text("\(summary.pendingApprovals)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.orange)
                                }
                                .padding()
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }

                        // Children Summary
                        if !familyService.children.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Children")
                                    .font(.headline)
                                    .padding(.horizontal)

                                ForEach(familyService.children) { child in
                                    ChildSummaryCard(child: child)
                                }
                            }
                        }

                        // Quick Actions
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Actions")
                                .font(.headline)
                                .padding(.horizontal)

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                QuickActionButton(icon: "plus.circle.fill", title: "Add Chore", color: .blue) {
                                    // TODO: Navigate to add chore
                                }
                                QuickActionButton(icon: "gift.fill", title: "Add Reward", color: .purple) {
                                    // TODO: Navigate to add reward
                                }
                                QuickActionButton(icon: "person.badge.plus", title: "Add Child", color: .green) {
                                    // TODO: Navigate to add child
                                }
                                QuickActionButton(icon: "chart.bar.fill", title: "View Reports", color: .orange) {
                                    // TODO: Navigate to reports
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .refreshable {
                await loadDashboardData()
            }
            .task {
                await loadDashboardData()
            }
        }
    }

    private func loadDashboardData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await familyService.loadFamily()
            try await choreService.loadChores()
            try await choreService.loadAssignments()
            try await choreService.loadCompletions()
            try await rewardsService.loadRewards()
            try await rewardsService.loadRedemptions()
            summary = await choreService.getDashboardSummary()
        } catch {
            print("Failed to load dashboard data: \(error)")
        }
    }
}

struct StatCard: View {
    let title: String
    let completed: Int
    let total: Int
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text("\(completed)/\(total)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            ProgressView(value: total > 0 ? Double(completed) / Double(total) : 0)
                .tint(color)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ChildSummaryCard: View {
    let child: Child

    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue.gradient)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(child.name.prefix(1)))
                        .font(.headline)
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(child.name)
                    .font(.headline)

                if let age = child.age {
                    Text("Age \(age)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("0 points") // TODO: Get actual points
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("0 completed") // TODO: Get actual completions
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}
```

## File: DatabaseAPI.swift

```swift
import Foundation
import Supabase

// Centralized PostgREST access using the *SDK* SupabaseClient.
// NOTE: Do NOT define your own type named `SupabaseClient` anywhere else.
final class DatabaseAPI {
    static let shared = DatabaseAPI()
    private let client = AppSupabase.shared.client
    private init() {}
    
    // Families
    func createFamily(_ family: Family) async throws -> Family {
        let inserted: [Family] = try await client
            .from("families")
            .insert([
                "id": family.id,
                "owner_id": family.ownerId,
                "name": family.name,
                "created_at": family.createdAt.ISO8601String()
            ], returning: .representation)
            .select()
            .execute()
            .value
        guard let first = inserted.first else { throw NSError(domain: "InsertFailed", code: 1) }
        return first
    }
    
    func fetchFamily(id: String) async throws -> Family? {
        let rows: [Family] = try await client
            .from("families")
            .select()
            .eq("id", value: id)
            .execute()
            .value
        return rows.first
    }
    
    // Children
    func createChild(_ child: Child) async throws -> Child {
        let rows: [Child] = try await client
            .from("children")
            .insert([
                "id": child.id,
                "parent_user_id": child.parentUserId,
                "name": child.name,
                "birthdate": child.birthdate?.ISO8601String(),
                "avatar_url": child.avatarURL,
                "created_at": child.createdAt.ISO8601String()
            ], returning: .representation)
            .select()
            .execute()
            .value
        guard let first = rows.first else { throw NSError(domain: "InsertFailed", code: 1) }
        return first
    }
    
    func fetchChildren(parentUserId: String) async throws -> [Child] {
        try await client
            .from("children")
            .select()
            .eq("parent_user_id", value: parentUserId)
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
```

## File: FamilyService.swift

```swift
import Foundation
import Combine

@MainActor
final class FamilyService: ObservableObject {
    static let shared = FamilyService()
    
    @Published var currentFamily: Family?
    @Published var children: [Child] = []
    @Published var familyMembers: [FamilyMember] = []
    
    private let authService = AuthService.shared
    
    private init() {}
    
    func loadFamily() async throws {
        guard let userId = authService.currentUser?.id else { return }
        if let family = try await DatabaseAPI.shared.fetchFamily(id: userId) {
            currentFamily = family
        }
        children = try await DatabaseAPI.shared.fetchChildren(parentUserId: userId)
    }
    
    func createChild(name: String, birthdate: Date?, pin: String) async throws {
        guard let userId = authService.currentUser?.id else { throw FamilyError.notAuthenticated }
        let child = Child(parentUserId: userId, name: name, birthdate: birthdate)
        let created = try await DatabaseAPI.shared.createChild(child)
        children.append(created)
    }
    
    func updateChild(_ child: Child) async throws {
        if let index = children.firstIndex(where: { $0.id == child.id }) { children[index] = child }
    }
    
    func deleteChild(_ child: Child) async throws {
        children.removeAll { $0.id == child.id }
    }
}

public struct FamilyMember: Identifiable, Codable, Equatable {
    public var id: String
    public var familyId: String
    public var userId: String?
    public var childName: String?
    public var age: Int?
    public var role: UserRole
    public var createdAt: Date?
}

enum FamilyError: LocalizedError {
    case notAuthenticated
    case familyNotFound
    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Not authenticated"
        case .familyNotFound: return "Family not found"
        }
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

## File: Models.swift

```swift
import Foundation

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

public struct DashboardSummary: Codable {
    public var todayAssigned = 0
    public var todayCompleted = 0
    public var thisWeekAssigned = 0
    public var thisWeekCompleted = 0
    public var pendingApprovals = 0
    public var childrenStats: [ChildStats] = []
    public var totalPointsEarned = 0
}

public struct ChildStats: Codable {
    public var childId: String
    public var displayName: String
    public var completedChores: Int = 0
    public var pendingChores: Int = 0
    public var weeklyPoints: Int = 0
    public var totalPoints: Int = 0
}

public extension Date {
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
    var isToday: Bool { Calendar.current.isDateInToday(self) }
    var isThisWeek: Bool { Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear) }
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

## File: ParentChoresView.swift

```swift
import SwiftUI

struct ParentChoresView: View { var body: some View { Text("Parent Chores") } }```

## File: ParentDashboardView.swift

```swift
import SwiftUI

struct ParentDashboardView: View { var body: some View { Text("Parent Dashboard") } }```

## File: ParentMainView.swift

```swift
import SwiftUI

struct ParentMainView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ParentDashboardView()
                .tabItem { Label("Dashboard", systemImage: "house.fill") }
                .tag(0)
            ParentChoresView()
                .tabItem { Label("Chores", systemImage: "checklist") }
                .tag(1)
            ApprovalsView()
                .tabItem { Label("Approvals", systemImage: "checkmark.seal.fill") }
                .tag(2)
            ReportsView()
                .tabItem { Label("Reports", systemImage: "doc.plaintext") }
                .tag(3)
            ParentSettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(4)
        }
    }
}```

## File: ParentRewardsView.swift

```swift

import SwiftUI

struct ParentRewardsView: View {
    @EnvironmentObject var rewardsService: RewardsService
    @State private var showingAddReward = false

    var body: some View {
        NavigationView {
            List {
                Section("Available Rewards") {
                    if rewardsService.rewards.isEmpty {
                        Text("No rewards created yet")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(rewardsService.rewards) { reward in
                            RewardRow(reward: reward)
                        }
                    }
                }
            }
            .navigationTitle("Rewards")
            .toolbar {
                Button {
                    showingAddReward = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingAddReward) {
                AddRewardView()
            }
            .task {
                try? await rewardsService.loadRewards()
            }
        }
    }
}

struct RewardRow: View {
    let reward: Reward

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(reward.name)
                    .font(.headline)
                Text("Cost: \(reward.costPoints) points")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "gift.fill")
                .foregroundColor(.purple)
        }
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
    
    @Published var rewards: [Reward] = []
    @Published var redemptions: [RewardRedemption] = []
    @Published var pointsLedger: [PointsLedger] = []
    
    private let authService = AuthService.shared
    
    private init() {}
    
    func loadRewards() async throws {
        guard let familyId = authService.currentUser?.familyId ?? authService.currentUser?.id else { return }
        rewards = [
            Reward(familyId: familyId, name: "Extra Screen Time", costPoints: 50),
            Reward(familyId: familyId, name: "Choose Dinner", costPoints: 100),
            Reward(familyId: familyId, name: "Stay Up Late", costPoints: 150)
        ]
    }
    
    func loadRedemptions() async throws { redemptions = [] }
    func loadPointsLedger() async throws { pointsLedger = [] }
    
    func createReward(_ reward: Reward) async throws { rewards.append(reward) }
    func updateReward(_ reward: Reward) async throws { if let i = rewards.firstIndex(where: { $0.id == reward.id }) { rewards[i] = reward } }
    func deleteReward(_ reward: Reward) async throws { rewards.removeAll { $0.id == reward.id } }
    
    func requestRedemption(rewardId: String, memberId: String) async throws {
        guard let reward = rewards.first(where: { $0.id == rewardId }) else { return }
        let balance = await getPointsBalance(for: memberId)
        guard balance >= reward.costPoints else { throw RewardsError.insufficientPoints }
        let redemption = RewardRedemption(rewardId: rewardId, memberId: memberId, status: .requested, requestedAt: Date())
        redemptions.append(redemption)
    }
    
    func approveRedemption(_ redemption: RewardRedemption) async throws {
        guard let reward = rewards.first(where: { $0.id == redemption.rewardId }),
              let familyId = authService.currentUser?.familyId ?? authService.currentUser?.id else { return }
        var updated = redemption
        updated.status = .approved
        updated.decidedBy = authService.currentUser?.id
        updated.decidedAt = Date()
        if let i = redemptions.firstIndex(where: { $0.id == redemption.id }) { redemptions[i] = updated }
        let entry = PointsLedger(familyId: familyId, memberId: redemption.memberId, delta: -reward.costPoints, reason: "Redeemed: \(reward.name)", event: .rewardRedeemed)
        pointsLedger.append(entry)
    }
    
    func rejectRedemption(_ redemption: RewardRedemption) async throws {
        var updated = redemption
        updated.status = .rejected
        updated.decidedBy = authService.currentUser?.id
        updated.decidedAt = Date()
        if let i = redemptions.firstIndex(where: { $0.id == redemption.id }) { redemptions[i] = updated }
    }
    
    func addPoints(to memberId: String, amount: Int, reason: String, event: PointsEvent) async throws {
        guard let familyId = authService.currentUser?.familyId ?? authService.currentUser?.id else { return }
        let entry = PointsLedger(familyId: familyId, memberId: memberId, delta: amount, reason: reason, event: event)
        pointsLedger.append(entry)
    }
    
    func getPointsBalance(for memberId: String) async -> Int {
        pointsLedger.filter { $0.memberId == memberId }.reduce(0) { $0 + $1.delta }
    }
    
    func getPointsHistory(for memberId: String) -> [PointsLedger] {
        pointsLedger.filter { $0.memberId == memberId }.sorted { $0.createdAt > $1.createdAt }
    }
    
    func getPendingRedemptions() -> [RewardRedemption] {
        redemptions.filter { $0.status == .requested }
    }
}

enum RewardsError: LocalizedError {
    case insufficientPoints
    case rewardNotFound
    var errorDescription: String? {
        switch self {
        case .insufficientPoints: return "Insufficient points for this reward"
        case .rewardNotFound: return "Reward not found"
        }
    }
}
```

## File: RootView.swift

```swift
import SwiftUI

struct RootView: View {
    @EnvironmentObject var authService: AuthService
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                SplashView()
                    .task {
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        isLoading = false
                    }
            } else {
                ContentView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
        .animation(.easeInOut(duration: 0.3), value: authService.isAuthenticated)
    }
}

struct SplashView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "house.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            Text("Allowance Alley")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            ProgressView()
                .scaleEffect(1.2)
                .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
}```

## File: StorageAPI.swift

```swift
import Foundation
import Supabase

// Keep ONE definition of StorageAPI in the project.
final class StorageAPI {
    static let shared = StorageAPI()
    private let client = AppSupabase.shared.client
    private init() {}
    
    @discardableResult
    func uploadImage(_ data: Data, bucket: String, path: String) async throws -> String {
        // Upload
        try await client.storage.from(bucket).upload(path: path, file: data)
        // Get a public URL
        let publicURL = try client.storage.from(bucket).getPublicURL(path: path)
        return publicURL.absoluteString
    }
    
    func downloadImage(bucket: String, path: String) async throws -> Data {
        try await client.storage.from(bucket).download(path: path)
    }
}
```

## File: TodayView.swift

```swift
//
//  TodayView.swift
//  AllowanceAlleyNextgen
//
//  Created by Paul Marshall on 8/22/25.
//

import SwiftUI

/// Minimal child-centric "today" screen so the app compiles and runs.
/// You can flesh this out later with real assignments and points.
struct TodayView: View {
    let childId: String

    var body: some View {
        VStack(spacing: 16) {
            Text("Today")
                .font(.largeTitle).bold()

            Text("Child ID: \(childId)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            Text("This is a stub view.\nWire chores, points, and approvals here.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        }
        .padding()
    }
}

#Preview {
    TodayView(childId: "demo-child-123")
}
```

