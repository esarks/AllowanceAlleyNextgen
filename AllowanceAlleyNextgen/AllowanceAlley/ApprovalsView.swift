
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
