import SwiftUI

struct ParentDashboardView: View {
    @EnvironmentObject var family: FamilyService
    @EnvironmentObject var chores: ChoreService
    @EnvironmentObject var rewards: RewardsService
    @State private var showAddChild = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Family Overview
                VStack(alignment: .leading, spacing: 12) {
                    Text("Family Overview")
                        .font(.title2)
                        .fontWeight(.semibold)

                    HStack {
                        StatCard(
                            title: "Active Chores",
                            completed: completedChoresCount,
                            total: chores.chores.count,
                            color: .blue
                        )
                        
                        StatCard(
                            title: "Pending Approvals",
                            completed: chores.pendingApprovals.count,
                            total: chores.pendingApprovals.count,
                            color: .orange
                        )
                    }
                }

                // Quick Actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Actions")
                        .font(.title2)
                        .fontWeight(.semibold)

                    LazyVGrid(columns: columns, spacing: 16) {
                        QuickActionButton(
                            icon: "person.badge.plus",
                            title: "Add Child",
                            color: .green
                        ) {
                            showAddChild = true
                        }

                        QuickActionButton(
                            icon: "plus.circle",
                            title: "Create Chore",
                            color: .blue
                        ) {
                            // Navigate to add chore - we'll implement this
                        }

                        QuickActionButton(
                            icon: "gift",
                            title: "Add Reward",
                            color: .purple
                        ) {
                            // Navigate to add reward
                        }

                        QuickActionButton(
                            icon: "checkmark.circle",
                            title: "Review Tasks",
                            color: .orange
                        ) {
                            // Navigate to approvals
                        }
                    }
                }

                // Family Members
                VStack(alignment: .leading, spacing: 12) {
                    Text("Family Members")
                        .font(.title2)
                        .fontWeight(.semibold)

                    if family.members.isEmpty {
                        Text("No family members yet. Add your first child!")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(family.members, id: \.id) { member in
                            FamilyMemberCard(member: member)
                        }
                    }
                }

                Spacer(minLength: 100)
            }
            .padding()
        }
        .navigationTitle("Dashboard")
        .sheet(isPresented: $showAddChild) {
            AddChildView()
        }
    }

    private var completedChoresCount: Int {
        chores.completions.filter { $0.status == .approved }.count
    }
}

struct FamilyMemberCard: View {
    let member: FamilyMember

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(member.role == .child ? Color.blue.opacity(0.15) : Color.green.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: member.role == .child ? "person.fill" : "crown.fill")
                        .foregroundColor(member.role == .child ? .blue : .green)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(member.childName ?? "Family Member")
                    .font(.headline)
                Text(member.role.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if member.role == .child {
                Text("0 pts") // Placeholder - you'd calculate actual points
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}
