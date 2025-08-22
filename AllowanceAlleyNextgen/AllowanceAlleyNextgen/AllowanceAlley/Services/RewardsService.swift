import Foundation
import Combine
import SwiftUI

@MainActor
final class RewardsService: ObservableObject {
    static let shared = RewardsService()

    @Published var rewards: [Reward] = []
    @Published var redemptions: [Redemption] = []
    @Published var pointsLedger: [PointsLedger] = []

    private init() {}

    // MARK: - Rewards Management (in-memory stubs so UI compiles/works)
    func createReward(_ reward: Reward) async throws {
        rewards.append(reward)
    }
    func updateReward(_ reward: Reward) async throws {
        if let idx = rewards.firstIndex(where: { $0.id == reward.id }) {
            rewards[idx] = reward
        }
    }
    func deleteReward(_ reward: Reward) async throws {
        rewards.removeAll { $0.id == reward.id }
    }
    func loadRewards() async throws {
        // no-op for stub
    }

    // MARK: - Redemption
    func requestRedemption(rewardId: String, childId: String) async throws {
        guard let reward = rewards.first(where: { $0.id == rewardId }) else { return }
        let balance = await getPointsBalance(for: childId)
        guard balance >= reward.costPoints else { return }
        let r = Redemption(rewardId: rewardId, childId: childId)
        redemptions.append(r)
    }
    func approveRedemption(_ redemption: Redemption) async throws {
        guard let idx = redemptions.firstIndex(where: { $0.id == redemption.id }) else { return }
        var r = redemptions[idx]
        r.status = .approved
        r.decidedAt = Date()
        r.updatedAt = Date()
        redemptions[idx] = r
        if let reward = rewards.first(where: { $0.id == r.rewardId }) {
            try await addPoints(to: r.childId, amount: -reward.costPoints, reason: "Redeemed: \(reward.title)", relatedId: r.id)
        }
    }
    func rejectRedemption(_ redemption: Redemption) async throws {
        guard let idx = redemptions.firstIndex(where: { $0.id == redemption.id }) else { return }
        var r = redemptions[idx]
        r.status = .rejected
        r.decidedAt = Date()
        r.updatedAt = Date()
        redemptions[idx] = r
    }
    func fulfillRedemption(_ redemption: Redemption) async throws {
        guard let idx = redemptions.firstIndex(where: { $0.id == redemption.id }) else { return }
        var r = redemptions[idx]
        r.status = .fulfilled
        r.fulfilledAt = Date()
        r.updatedAt = Date()
        redemptions[idx] = r
    }
    func loadRedemptions() async throws {
        // no-op for stub
    }
    func getPendingRedemptions() -> [Redemption] {
        redemptions.filter { $0.status == .requested }
    }

    // MARK: - Points
    func addPoints(to childId: String, amount: Int, reason: String, relatedId: String? = nil) async throws {
        pointsLedger.append(PointsLedger(childId: childId, deltaPoints: amount, reason: reason, relatedId: relatedId))
    }
    func loadPointsLedger() async throws {
        // no-op for stub
    }
    func getPointsBalance(for childId: String) async -> Int {
        pointsLedger.filter{ $0.childId == childId }.map{ $0.deltaPoints }.reduce(0, +)
    }
    func getPointsHistory(for childId: String) -> [PointsLedger] {
        pointsLedger.filter{ $0.childId == childId }.sorted{ $0.createdAt > $1.createdAt }
    }
}
