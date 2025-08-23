
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
