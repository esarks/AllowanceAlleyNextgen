import SwiftUI

struct ChildDashboardView: View {
    let childId: String
    @EnvironmentObject var choreService: ChoreService
    @EnvironmentObject var rewardsService: RewardsService
    @EnvironmentObject var familyService: FamilyService
    @State private var pointsBalance = 0
    @State private var todayAssignments: [ChoreAssignment] = []
    @State private var completedToday = 0
    @State private var pendingApprovals = 0

    private var childName: String {
        familyService.children.first { $0.id == childId }?.name ?? "Me"
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Welcome Header with Points
                    welcomeHeader
                    
                    // Today's Chores Section
                    todaysChoresSection
                    
                    // Quick Stats
                    quickStatsSection
                    
                    // Available Rewards Preview
                    rewardsPreviewSection
                    
                    // Recent Activity
                    recentActivitySection
                }
                .padding()
            }
            .navigationTitle("Hi, \(childName)! 👋")
            .task {
                await loadChildData()
            }
            .refreshable {
                await loadChildData()
            }
        }
    }
    
    private var welcomeHeader: some View {
        VStack(spacing: 12) {
            // Points Display
            VStack(spacing: 8) {
                Text("My Points")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Text("\(pointsBalance)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.blue)
                
                if pointsBalance > 0 {
                    Text("Great job earning points!")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("Complete chores to earn points!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
        }
    }
    
    private var todaysChoresSection: some View {
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
                    Text("Check back tomorrow for new chores")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 80)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            } else {
                ForEach(todayAssignments.prefix(3)) { assignment in
                    ChildChoreCard(assignment: assignment, childId: childId)
                }

                if todayAssignments.count > 3 {
                    NavigationLink(destination: ChildChoresView(childId: childId)) {
                        HStack {
                            Text("View all \(todayAssignments.count) chores")
                                .font(.subheadline)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private var quickStatsSection: some View {
        HStack(spacing: 16) {
            StatBox(
                title: "Completed Today",
                value: "\(completedToday)",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            StatBox(
                title: "Pending Approval",
                value: "\(pendingApprovals)",
                icon: "clock.fill",
                color: .orange
            )
        }
    }
    
    private var rewardsPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Available Rewards")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: ChildRewardsView(childId: childId)) {
                    Text("See All")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            if rewardsService.rewards.isEmpty {
                Text("No rewards available yet")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(rewardsService.rewards.prefix(3)) { reward in
                            RewardPreviewCard(reward: reward, canAfford: pointsBalance >= reward.costPoints)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)

            let recentHistory = rewardsService.getPointsHistory(for: childId).prefix(3)
            
            if recentHistory.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("No activity yet")
                        .foregroundColor(.secondary)
                    Text("Complete chores to see your progress here")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                ForEach(Array(recentHistory)) { entry in
                    HStack {
                        Image(systemName: entry.delta > 0 ? "plus.circle.fill" : "minus.circle.fill")
                            .foregroundColor(entry.delta > 0 ? .green : .red)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.reason ?? "Points activity")
                                .font(.subheadline)
                            Text(entry.createdAt, style: .relative)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(entry.delta > 0 ? "+" : "")\(entry.delta) pts")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(entry.delta > 0 ? .green : .red)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }

    private func loadChildData() async {
        todayAssignments = choreService.getTodayAssignments(for: childId)
        pointsBalance = await rewardsService.getPointsBalance(for: childId)
        
        // Calculate today's completed chores
        let todayCompletions = choreService.completions.filter { completion in
            completion.submittedBy == childId && 
            completion.status == .approved &&
            completion.completedAt?.isToday == true
        }
        completedToday = todayCompletions.count
        
        // Calculate pending approvals for this child
        pendingApprovals = choreService.completions.filter { completion in
            completion.submittedBy == childId && completion.status == .pending
        }.count
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct RewardPreviewCard: View {
    let reward: Reward
    let canAfford: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "gift.fill")
                .font(.title2)
                .foregroundColor(canAfford ? .purple : .secondary)
            
            Text(reward.name)
                .font(.caption)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Text("\(reward.costPoints) pts")
                .font(.caption)
                .foregroundColor(canAfford ? .blue : .secondary)
        }
        .frame(width: 80, height: 80)
        .padding(8)
        .background(canAfford ? Color.purple.opacity(0.1) : Color.secondary.opacity(0.1))
        .cornerRadius(12)
        .opacity(canAfford ? 1.0 : 0.6)
    }
}