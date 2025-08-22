
import SwiftUI

struct ChildRewardsView: View {
    let childId: String
    @EnvironmentObject var rewardsService: RewardsService
    @State private var pointsBalance = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Points Header
                VStack(spacing: 8) {
                    Text("My Points")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("\(pointsBalance)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.blue)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))

                List {
                    Section("Available Rewards") {
                        if rewardsService.rewards.isEmpty {
                            Text("No rewards available yet")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            ForEach(rewardsService.rewards) { reward in
                                ChildRewardRow(reward: reward, childId: childId, canAfford: pointsBalance >= reward.costPoints)
                            }
                        }
                    }

                    Section("My Requests") {
                        let myRedemptions = rewardsService.redemptions.filter { $0.memberId == childId }

                        if myRedemptions.isEmpty {
                            Text("No reward requests yet")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            ForEach(myRedemptions) { redemption in
                                RedemptionStatusRow(redemption: redemption)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Rewards")
            .task {
                pointsBalance = await rewardsService.getPointsBalance(for: childId)
            }
        }
    }
}

struct ChildRewardRow: View {
    let reward: Reward
    let childId: String
    let canAfford: Bool
    @EnvironmentObject var rewardsService: RewardsService
    @State private var isRequesting = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(reward.name)
                    .font(.headline)
                    .foregroundColor(canAfford ? .primary : .secondary)

                Text("\(reward.costPoints) points")
                    .font(.subheadline)
                    .foregroundColor(canAfford ? .blue : .secondary)
            }

            Spacer()

            Button("Request") {
                isRequesting = true
                Task {
                    try? await rewardsService.requestRedemption(rewardId: reward.id, memberId: childId)
                    isRequesting = false
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canAfford || isRequesting)
        }
        .opacity(canAfford ? 1.0 : 0.6)
    }
}

struct RedemptionStatusRow: View {
    let redemption: RewardRedemption
    @EnvironmentObject var rewardsService: RewardsService

    private var rewardName: String {
        rewardsService.rewards.first { $0.id == redemption.rewardId }?.name ?? "Unknown Reward"
    }

    private var statusColor: Color {
        switch redemption.status {
        case .requested: return .orange
        case .approved: return .green
        case .rejected: return .red
        case .fulfilled: return .blue
        }
    }

    private var statusText: String {
        switch redemption.status {
        case .requested: return "Pending"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        case .fulfilled: return "Fulfilled"
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(rewardName)
                    .font(.headline)

                if let requestedAt = redemption.requestedAt {
                    Text("Requested: \(requestedAt, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text(statusText)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.2))
                .cornerRadius(8)
        }
    }
}
