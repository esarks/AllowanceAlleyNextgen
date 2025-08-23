
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
                    if let familyName = authService.currentUser?.familyId {
                        HStack {
                            Text("Family ID"); Spacer()
                            Text(familyName).font(.caption).foregroundColor(.secondary)
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

struct RewardsView: View {
    let childId: String
    let familyId: String?   // keep for back-compat if anything still passes it
    init(childId: String, familyId: String? = nil) {
        self.childId = childId
        self.familyId = familyId
    }
    var body: some View { ChildRewardsView(childId: childId) }
}

