
import SwiftUI

struct ParentRewardsView: View {
    @EnvironmentObject var rewardsService: RewardsService
    @State private var showingAddReward = false

    var body: some View {
        NavigationView {
            List {
                Section("Available Rewards") {
                    if rewardsService.rewards.isEmpty {
                        Text("No rewards created yet")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(rewardsService.rewards) { reward in
                            RewardRow(reward: reward)
                        }
                    }
                }
            }
            .navigationTitle("Rewards")
            .toolbar {
                Button {
                    showingAddReward = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingAddReward) {
                AddRewardView()
            }
            .task {
                try? await rewardsService.loadRewards()
            }
        }
    }
}

struct RewardRow: View {
    let reward: Reward

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(reward.name)
                    .font(.headline)
                Text("Cost: \(reward.costPoints) points")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "gift.fill")
                .foregroundColor(.purple)
        }
    }
}
