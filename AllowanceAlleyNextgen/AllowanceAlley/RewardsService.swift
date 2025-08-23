import Foundation
import Combine

@MainActor
final class RewardsService: ObservableObject {
    static let shared = RewardsService()

    @Published private(set) var rewards: [Reward] = []
    @Published private(set) var redemptions: [RewardRedemption] = []
    @Published private(set) var pointsLedger: [PointsLedger] = []

    private let auth = AuthService.shared
    private let db = DatabaseAPI.shared
    private init() {}

    func loadAll() async {
        guard let familyId = auth.currentUser?.familyId ?? auth.currentUser?.id else { return }
        async let a = loadRewards(familyId: familyId)
        async let b = loadRedemptions(familyId: familyId)
        _ = await (a, b)
    }

    func loadRewards(familyId: String) async {
        do { rewards = try await db.fetchRewards(familyId: familyId) } catch { print(error) }
    }

    func loadRedemptions(familyId: String) async {
        do { redemptions = try await db.fetchRedemptions(familyId: familyId) } catch { print(error) }
    }

    func loadPoints(for memberId: String) async {
        guard let familyId = auth.currentUser?.familyId ?? auth.currentUser?.id else { return }
        do { pointsLedger = try await db.fetchLedger(familyId: familyId, memberId: memberId) } catch { print(error) }
    }

    func createReward(_ reward: Reward) async throws {
        let created = try await db.createReward(reward)
        rewards.append(created)
    }

    func updateReward(_ reward: Reward) async throws {
        let updated = try await db.updateReward(reward)
        if let i = rewards.firstIndex(where: { $0.id == updated.id }) { rewards[i] = updated }
    }

    func deleteReward(_ reward: Reward) async throws {
        try await db.deleteReward(id: reward.id)
        rewards.removeAll { $0.id == reward.id }
    }

    func requestRedemption(rewardId: String, memberId: String) async throws {
        let r = try await db.requestRedemption(rewardId: rewardId, memberId: memberId)
        redemptions.insert(r, at: 0)
    }

    func approveRedemption(_ redemption: RewardRedemption) async throws {
        guard let decider = auth.currentUser?.id else { return }
        let updated = try await db.setRedemptionStatus(id: redemption.id, status: "approved", decidedBy: decider)
        if let i = redemptions.firstIndex(where: { $0.id == updated.id }) { redemptions[i] = updated }

        // optional: write the negative points to the ledger
        if let reward = rewards.first(where: { $0.id == redemption.rewardId }),
           let familyId = auth.currentUser?.familyId ?? auth.currentUser?.id {
            let entry = PointsLedger(
                familyId: familyId,
                memberId: redemption.memberId,
                delta: -reward.costPoints,
                reason: "Redeemed: \(reward.name)",
                event: .rewardRedeemed
            )
            let saved = try await db.addLedgerEntry(entry)
            pointsLedger.insert(saved, at: 0)
        }
    }

    func rejectRedemption(_ redemption: RewardRedemption) async throws {
        guard let decider = auth.currentUser?.id else { return }
        let updated = try await db.setRedemptionStatus(id: redemption.id, status: "rejected", decidedBy: decider)
        if let i = redemptions.firstIndex(where: { $0.id == updated.id }) { redemptions[i] = updated }
    }
}
