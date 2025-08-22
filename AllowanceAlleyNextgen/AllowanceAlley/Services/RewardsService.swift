//
//  RewardsService.swift
//  AllowanceAlley
//

import Foundation
import Combine

class RewardsService: ObservableObject {
    static let shared = RewardsService()
    
    @Published var rewards: [Reward] = []
    @Published var redemptions: [Redemption] = []
    @Published var pointsLedger: [PointsLedger] = []
    
    private let supabaseClient = SupabaseClient.shared
    private let coreDataStack = CoreDataStack.shared
    private let authService = AuthService.shared
    private let familyService = FamilyService.shared
    
    private init() {}
    
    // MARK: - Rewards Management
    
    func createReward(_ reward: Reward) async throws {
        let createdReward: Reward = try await supabaseClient.insert("rewards", values: reward)
        
        await MainActor.run {
            self.rewards.append(createdReward)
        }
    }
    
    func updateReward(_ reward: Reward) async throws {
        let updatedReward: Reward = try await supabaseClient.update("rewards", values: reward, matching: "id", value: reward.id)
        
        await MainActor.run {
            if let index = self.rewards.firstIndex(where: { $0.id == reward.id }) {
                self.rewards[index] = updatedReward
            }
        }
    }
    
    func deleteReward(_ reward: Reward) async throws {
        try await supabaseClient.delete("rewards", matching: "id", value: reward.id)
        
        await MainActor.run {
            self.rewards.removeAll { $0.id == reward.id }
        }
    }
    
    func loadRewards() async throws {
        guard let family = familyService.currentFamily else { return }
        
        let loadedRewards: [Reward] = try await supabaseClient.client.database
            .from("rewards")
            .select()
            .eq("family_id", value: family.id)
            .eq("is_active", value: true)
            .execute()
            .value
        
        await MainActor.run {
            self.rewards = loadedRewards
        }
    }
    
    // MARK: - Redemption Management
    
    func requestRedemption(rewardId: String, childId: String) async throws {
        // Check if child has enough points
        let balance = await getPointsBalance(for: childId)
        guard let reward = rewards.first(where: { $0.id == rewardId }),
              balance >= reward.costPoints else {
            throw RewardsError.insufficientPoints
        }
        
        let redemption = Redemption(
            rewardId: rewardId,
            childId: childId
        )
        
        let createdRedemption: Redemption = try await supabaseClient.insert("redemptions", values: redemption)
        
        await MainActor.run {
            self.redemptions.append(createdRedemption)
        }
    }
    
    func approveRedemption(_ redemption: Redemption) async throws {
        var updatedRedemption = redemption
        updatedRedemption.status = .approved
        updatedRedemption.decidedAt = Date()
        updatedRedemption.updatedAt = Date()
        
        let _: Redemption = try await supabaseClient.update("redemptions", values: updatedRedemption, matching: "id", value: redemption.id)
        
        await MainActor.run {
            if let index = self.redemptions.firstIndex(where: { $0.id == redemption.id }) {
                self.redemptions[index] = updatedRedemption
            }
        }
        
        // Deduct points
        if let reward = rewards.first(where: { $0.id == redemption.rewardId }) {
            try await addPoints(
                to: redemption.childId,
                amount: -reward.costPoints,
                reason: "Redeemed: \(reward.title)",
                relatedId: redemption.id
            )
        }
    }
    
    func rejectRedemption(_ redemption: Redemption) async throws {
        var updatedRedemption = redemption
        updatedRedemption.status = .rejected
        updatedRedemption.decidedAt = Date()
        updatedRedemption.updatedAt = Date()
        
        let _: Redemption = try await supabaseClient.update("redemptions", values: updatedRedemption, matching: "id", value: redemption.id)
        
        await MainActor.run {
            if let index = self.redemptions.firstIndex(where: { $0.id == redemption.id }) {
                self.redemptions[index] = updatedRedemption
            }
        }
    }
    
    func fulfillRedemption(_ redemption: Redemption) async throws {
        var updatedRedemption = redemption
        updatedRedemption.status = .fulfilled
        updatedRedemption.fulfilledAt = Date()
        updatedRedemption.updatedAt = Date()
        
        let _: Redemption = try await supabaseClient.update("redemptions", values: updatedRedemption, matching: "id", value: redemption.id)
        
        await MainActor.run {
            if let index = self.redemptions.firstIndex(where: { $0.id == redemption.id }) {
                self.redemptions[index] = updatedRedemption
            }
        }
    }
    
    func loadRedemptions() async throws {
        guard let family = familyService.currentFamily else { return }
        
        let loadedRedemptions: [Redemption] = try await supabaseClient.client.database
            .from("redemptions")
            .select("*, rewards!inner(family_id)")
            .eq("rewards.family_id", value: family.id)
            .execute()
            .value
        
        await MainActor.run {
            self.redemptions = loadedRedemptions
        }
    }
    
    func getPendingRedemptions() -> [Redemption] {
        redemptions.filter { $0.status == .requested }
    }
    
    // MARK: - Points Management
    
    func addPoints(to childId: String, amount: Int, reason: String, relatedId: String? = nil) async throws {
        let ledgerEntry = PointsLedger(
            childId: childId,
            deltaPoints: amount,
            reason: reason,
            relatedId: relatedId
        )
        
        let _: PointsLedger = try await supabaseClient.insert("points_ledger", values: ledgerEntry)
        
        await MainActor.run {
            self.pointsLedger.append(ledgerEntry)
        }
    }
    
    func loadPointsLedger() async throws {
        guard let family = familyService.currentFamily else { return }
        
        let childIds = familyService.children.map { $0.id }
        guard !childIds.isEmpty else { return }
        
        let ledger: [PointsLedger] = try await supabaseClient.client.database
            .from("points_ledger")
            .select()
            .in("child_id", values: childIds)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        await MainActor.run {
            self.pointsLedger = ledger
        }
    }
    
    func getPointsBalance(for childId: String) async -> Int {
        await loadPointsLedger()
        return pointsLedger
            .filter { $0.childId == childId }
            .reduce(0) { $0 + $1.deltaPoints }
    }
    
    func getPointsHistory(for childId: String) -> [PointsLedger] {
        pointsLedger
            .filter { $0.childId == childId }
            .sorted { $0.createdAt > $1.createdAt }
    }
}

enum RewardsError: LocalizedError {
    case insufficientPoints
    case rewardNotFound
    case redemptionNotFound
    
    var errorDescription: String? {
        switch self {
        case .insufficientPoints:
            return "Insufficient points"
        case .rewardNotFound:
            return "Reward not found"
        case .redemptionNotFound:
            return "Redemption not found"
        }
    }
}