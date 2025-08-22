
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
