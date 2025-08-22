import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var familyService: FamilyService
    @EnvironmentObject var choreService: ChoreService
    @EnvironmentObject var rewardsService: RewardsService
    
    @State private var summary = DashboardSummary()
    @State private var showingFamilyManager = false
    @State private var showingChoreBuilder = false
    @State private var showingRewardsManager = false
    @State private var showingSettings = false
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            NavigationView {
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Welcome back!")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Button(action: { showingSettings = true }) {
                                    Image(systemName: "gearshape.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                                .accessibilityLabel("Settings")
                            }
                            
                            if let family = familyService.currentFamily {
                                Text(family.name)
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Quick Stats
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                            StatCard(
                                title: "Today",
                                completed: summary.todayCompleted,
                                total: summary.todayAssigned,
                                color: .blue
                            )
                            
                            StatCard(
                                title: "This Week",
                                completed: summary.thisWeekCompleted,
                                total: summary.thisWeekAssigned,
                                color: .green
                            )
                            
                            StatCard(
                                title: "Pending Approvals",
                                completed: summary.pendingApprovals,
                                total: summary.pendingApprovals,
                                color: .orange,
                                showAsCount: true
                            )
                            
                            StatCard(
                                title: "Active Children",
                                completed: familyService.children.count,
                                total: familyService.children.count,
                                color: .purple,
                                showAsCount: true
                            )
                        }
                        .padding(.horizontal)
                        
                        // Children Overview
                        if !summary.childrenStats.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Children Overview")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(summary.childrenStats, id: \.childId) { stats in
                                    ChildStatsCard(stats: stats)
                                }
                            }
                        }
                        
                        // Quick Actions
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Actions")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                QuickActionButton(
                                    title: "Add Chore",
                                    icon: "plus.circle.fill",
                                    color: .blue
                                ) {
                                    showingChoreBuilder = true
                                }
                                
                                QuickActionButton(
                                    title: "Manage Family",
                                    icon: "person.2.fill",
                                    color: .green
                                ) {
                                    showingFamilyManager = true
                                }
                                
                                QuickActionButton(
                                    title: "Add Reward",
                                    icon: "gift.fill",
                                    color: .orange
                                ) {
                                    showingRewardsManager = true
                                }
                                
                                NavigationLink(destination: ApprovalsInboxView()) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                        
                                        Text("Approvals")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 60)
                                    .background(Color.purple)
                                    .cornerRadius(12)
                                }
                                .accessibilityLabel("View pending approvals")
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .navigationBarHidden(true)
                .refreshable {
                    await loadDashboardData()
                }
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Dashboard")
            }
            .tag(0)
            
            // Chores Tab
            NavigationView {
                ChoreListView()
            }
            .tabItem {
                Image(systemName: "list.bullet")
                Text("Chores")
            }
            .tag(1)
            
            // Rewards Tab
            NavigationView {
                RewardsShopView()
            }
            .tabItem {
                Image(systemName: "gift.fill")
                Text("Rewards")
            }
            .tag(2)
            
            // Family Tab
            NavigationView {
                FamilyManagerView()
            }
            .tabItem {
                Image(systemName: "person.2.fill")
                Text("Family")
            }
            .tag(3)
        }
        .sheet(isPresented: $showingChoreBuilder) {
            ChoreBuilderView()
        }
        .sheet(isPresented: $showingFamilyManager) {
            FamilyManagerView()
        }
        .sheet(isPresented: $showingRewardsManager) {
            RewardManagerView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .onAppear {
            Task {
                await loadDashboardData()
            }
        }
    }
    
    private func loadDashboardData() async {
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
    var showAsCount: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if showAsCount {
                Text("\(completed)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            } else {
                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(completed)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                    
                    Text("/ \(total)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if total > 0 {
                    ProgressView(value: Double(completed), total: Double(total))
                        .progressViewStyle(LinearProgressViewStyle(tint: color))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .accessibilityLabel("\(title): \(showAsCount ? "\(completed)" : "\(completed) of \(total) completed")")
    }
}

struct ChildStatsCard: View {
    let stats: ChildStats
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue)
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(stats.displayName.prefix(2)).uppercased())
                        .font(.headline)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(stats.displayName)
                    .font(.headline)
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("Points")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(stats.totalPoints)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Completed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(stats.completedChores)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Pending")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(stats.pendingChores)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal)
        .accessibilityLabel("\(stats.displayName): \(stats.totalPoints) points, \(stats.completedChores) completed chores, \(stats.pendingChores) pending chores")
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(color)
            .cornerRadius(12)
        }
        .accessibilityLabel(title)
    }
}

struct ChoreListView: View {
    @EnvironmentObject var choreService: ChoreService
    @State private var showingChoreBuilder = false
    
    var body: some View {
        List {
            ForEach(choreService.chores) { chore in
                ChoreRowView(chore: chore)
            }
        }
        .navigationTitle("Chores")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add") {
                    showingChoreBuilder = true
                }
                .accessibilityLabel("Add Chore")
            }
        }
        .sheet(isPresented: $showingChoreBuilder) {
            ChoreBuilderView()
        }
        .onAppear {
            Task {
                try await choreService.loadChores()
            }
        }
    }
}

struct ChoreRowView: View {
    let chore: Chore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(chore.title)
                    .font(.headline)
                
                Spacer()
                
                Text("\(chore.points) pts")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
            }
            
            if let description = chore.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text(chore.recurrence?.capitalized ?? "One-time")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if chore.requirePhoto {
                    Image(systemName: "camera.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

struct RewardManagerView: View {
    @EnvironmentObject var rewardsService: RewardsService
    @EnvironmentObject var familyService: FamilyService
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var costPoints = ""
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Reward Details") {
                    TextField("Name", text: $name)
                        .accessibilityLabel("Reward Name")
                    TextField("Cost (Points)", text: $costPoints)
                        .keyboardType(.numberPad)
                        .accessibilityLabel("Cost in Points")
                }
                
                Section("Existing Rewards") {
                    ForEach(rewardsService.rewards) { reward in
                        VStack(alignment: .leading) {
                            Text(reward.name)
                                .font(.headline)
                            Text("\(reward.costPoints) points")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .accessibilityLabel("\(reward.name), \(reward.costPoints) points")
                    }
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .accessibilityLabel("Error: \(errorMessage)")
                    }
                }
            }
            .navigationTitle("Manage Rewards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveReward()
                    }
                    .disabled(name.isEmpty || costPoints.isEmpty)
                    .accessibilityLabel("Save Reward")
                }
            }
        }
    }
    
    private func saveReward() {
        guard let points = Int(costPoints),
              let family = familyService.currentFamily else { 
            errorMessage = "Invalid input"
            return 
        }
        
        let reward = Reward(
            familyId: family.id,
            name: name,
            costPoints: points
        )
        
        Task {
            try await rewardsService.createReward(reward)
            await MainActor.run {
                dismiss()
            }
        }
    }
}
