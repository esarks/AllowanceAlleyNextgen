
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
