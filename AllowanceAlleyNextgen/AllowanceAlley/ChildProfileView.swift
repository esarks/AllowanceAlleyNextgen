
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
