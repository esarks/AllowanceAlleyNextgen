import Foundation
import Combine

@MainActor
final class RewardsService: ObservableObject {
    static let shared = RewardsService()
    
    @Published var rewards: [Reward] = []
    @Published var redemptions: [RewardRedemption] = []
    @Published var pointsLedger: [PointsLedger] = []
    
    private let authService = AuthService.shared
    
    private init() {}
    
    func loadRewards() async throws {
        guard let familyId = authService.currentUser?.familyId ?? authService.currentUser?.id else { return }
        rewards = [
            Reward(familyId: familyId, name: "Extra Screen Time", costPoints: 50),
            Reward(familyId: familyId, name: "Choose Dinner", costPoints: 100),
            Reward(familyId: familyId, name: "Stay Up Late", costPoints: 150)
        ]
    }
    
    func loadRedemptions() async throws { redemptions = [] }
    func loadPointsLedger() async throws { pointsLedger = [] }
    
    func createReward(_ reward: Reward) async throws { rewards.append(reward) }
    func updateReward(_ reward: Reward) async throws { if let i = rewards.firstIndex(where: { $0.id == reward.id }) { rewards[i] = reward } }
    func deleteReward(_ reward: Reward) async throws { rewards.removeAll { $0.id == reward.id } }
    
    func requestRedemption(rewardId: String, memberId: String) async throws {
        guard let reward = rewards.first(where: { $0.id == rewardId }) else { return }
        let balance = await getPointsBalance(for: memberId)
        guard balance >= reward.costPoints else { throw RewardsError.insufficientPoints }
        let redemption = RewardRedemption(rewardId: rewardId, memberId: memberId, status: .requested, requestedAt: Date())
        redemptions.append(redemption)
    }
    
    func approveRedemption(_ redemption: RewardRedemption) async throws {
        guard let reward = rewards.first(where: { $0.id == redemption.rewardId }),
              let familyId = authService.currentUser?.familyId ?? authService.currentUser?.id else { return }
        var updated = redemption
        updated.status = .approved
        updated.decidedBy = authService.currentUser?.id
        updated.decidedAt = Date()
        if let i = redemptions.firstIndex(where: { $0.id == redemption.id }) { redemptions[i] = updated }
        let entry = PointsLedger(familyId: familyId, memberId: redemption.memberId, delta: -reward.costPoints, reason: "Redeemed: \(reward.name)", event: .rewardRedeemed)
        pointsLedger.append(entry)
    }
    
    func rejectRedemption(_ redemption: RewardRedemption) async throws {
        var updated = redemption
        updated.status = .rejected
        updated.decidedBy = authService.currentUser?.id
        updated.decidedAt = Date()
        if let i = redemptions.firstIndex(where: { $0.id == redemption.id }) { redemptions[i] = updated }
    }
    
    func addPoints(to memberId: String, amount: Int, reason: String, event: PointsEvent) async throws {
        guard let familyId = authService.currentUser?.familyId ?? authService.currentUser?.id else { return }
        let entry = PointsLedger(familyId: familyId, memberId: memberId, delta: amount, reason: reason, event: event)
        pointsLedger.append(entry)
    }
    
    func getPointsBalance(for memberId: String) async -> Int {
        pointsLedger.filter { $0.memberId == memberId }.reduce(0) { $0 + $1.delta }
    }
    
    func getPointsHistory(for memberId: String) -> [PointsLedger] {
        pointsLedger.filter { $0.memberId == memberId }.sorted { $0.createdAt > $1.createdAt }
    }
    
    func getPendingRedemptions() -> [RewardRedemption] {
        redemptions.filter { $0.status == .requested }
    }
}

enum RewardsError: LocalizedError {
    case insufficientPoints
    case rewardNotFound
    var errorDescription: String? {
        switch self {
        case .insufficientPoints: return "Insufficient points for this reward"
        case .rewardNotFound: return "Reward not found"
        }
    }
}
