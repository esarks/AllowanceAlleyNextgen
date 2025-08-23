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
