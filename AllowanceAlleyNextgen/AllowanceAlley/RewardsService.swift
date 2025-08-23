
import Foundation
import Combine

@MainActor
final class RewardsService: ObservableObject {
    static let shared = RewardsService()

    @Published private(set) var rewards: [Reward] = []
    @Published private(set) var redemptions: [RewardRedemption] = []
    @Published private(set) var points: [PointsLedger] = []

    private let auth = AuthService.shared
    private let db = DatabaseAPI.shared
    private init() {}

    func loadAll(familyId: String) async {
        async let a = loadRewards(familyId: familyId)
        async let b = loadRedemptions(familyId: familyId)
        _ = await (a, b)
    }

    func loadRewards(familyId: String) async {
        do { rewards = try await db.fetchRewards(familyId: familyId) } catch { print(error) }
    }

    func loadRedemptions(familyId: String) async {
        do { redemptions = try await db.fetchRedemptionsForFamily(familyId: familyId) } catch { print(error) }
    }

    func loadPointsFor(memberId: String) async {
        guard let familyId = auth.currentUser?.familyId ?? FamilyService.shared.family?.id else { return }
        do { points = try await db.fetchLedger(familyId: familyId, memberId: memberId) } catch { print(error) }
    }

    func createReward(familyId: String, name: String, costPoints: Int) async throws {
        let created = try await db.createReward(familyId: familyId, name: name, costPoints: costPoints)
        rewards.append(created)
    }

    func updateReward(_ reward: Reward) async throws {
        let updated = try await db.updateReward(reward: reward)
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

    func decide(_ redemption: RewardRedemption, approve: Bool) async throws {
        guard let decider = auth.currentUser?.id else { return }
        let status: RedemptionStatus = approve ? .approved : .rejected
        let updated = try await db.setRedemptionStatus(id: redemption.id, status: status, decidedBy: decider)
        if let i = redemptions.firstIndex(where: { $0.id == updated.id }) { redemptions[i] = updated }

        if approve,
           let familyId = auth.currentUser?.familyId ?? FamilyService.shared.family?.id,
           let reward = rewards.first(where: { $0.id == redemption.rewardId }) {
            let entry = PointsLedger(id: UUID().uuidString, familyId: familyId, memberId: redemption.memberId, delta: -reward.costPoints, reason: "Redeemed: \(reward.name)", event: "reward_redeemed", createdAt: nil)
            _ = try await db.addLedgerEntry(entry)
        }
    }
}
