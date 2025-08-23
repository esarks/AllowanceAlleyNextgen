import Foundation
import Supabase

struct DatabaseAPI {
    static let shared = DatabaseAPI()
    private let client = AppSupabase.shared.client
    private init() {}

    // MARK: - Families / Children

    func createFamily(name: String) async throws -> Family {
        try await client
            .from("families")
            .insert(["name": name], returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }

    func fetchFamily(for userId: String) async throws -> Family? {
        let rows: [Family] = try await client
            .from("families")
            .select()
            .eq("owner_user_id", value: userId)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    func createChild(familyId: String, displayName: String) async throws -> Child {
        try await client
            .from("children")
            .insert([
                "family_id": familyId,
                "display_name": displayName
            ], returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }

    func fetchChildren(familyId: String) async throws -> [Child] {
        try await client
            .from("children")
            .select()
            .eq("family_id", value: familyId)
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    func updateChild(_ child: Child) async throws -> Child {
        try await client
            .from("children")
            .update(child, returning: .representation)
            .eq("id", value: child.id)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteChild(id: String) async throws {
        _ = try await client
            .from("children")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Profiles

    func fetchProfile(userId: String) async throws -> AppUser? {
        let rows: [AppUser] = try await client
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    // MARK: - Chores

    func fetchChores(familyId: String) async throws -> [Chore] {
        try await client
            .from("chores")
            .select()
            .eq("family_id", value: familyId)
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    func createChore(_ chore: Chore) async throws -> Chore {
        try await client
            .from("chores")
            .insert(chore, returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }

    func updateChore(_ chore: Chore) async throws -> Chore {
        try await client
            .from("chores")
            .update(chore, returning: .representation)
            .eq("id", value: chore.id)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteChore(id: String) async throws {
        _ = try await client
            .from("chores")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Assignments

    func assignChore(choreId: String, memberId: String, due: Date) async throws -> ChoreAssignment {
        try await client
            .from("chore_assignments")
            .insert([
                "chore_id": choreId,
                "member_id": memberId,
                "due_date": ISO8601DateFormatter().string(from: due)
            ], returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }

    func fetchAssignments(familyId: String) async throws -> [ChoreAssignment] {
        try await client
            .from("chore_assignments")
            .select()
            .eq("family_id", value: familyId)
            .execute()
            .value
    }

    // MARK: - Completions

    func submitCompletion(_ completion: ChoreCompletion) async throws -> ChoreCompletion {
        try await client
            .from("chore_completions")
            .insert(completion, returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }

    func reviewCompletion(id: String, status: String, reviewedBy: String) async throws -> ChoreCompletion {
        try await client
            .from("chore_completions")
            .update([
                "status": status,
                "reviewed_by": reviewedBy,
                "reviewed_at": ISO8601DateFormatter().string(from: Date())
            ], returning: .representation)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
    }

    func fetchCompletions(familyId: String) async throws -> [ChoreCompletion] {
        try await client
            .from("chore_completions")
            .select()
            .eq("family_id", value: familyId)
            .order("completed_at", ascending: false)
            .execute()
            .value
    }

    // MARK: - Rewards

    func fetchRewards(familyId: String) async throws -> [Reward] {
        try await client
            .from("rewards")
            .select()
            .eq("family_id", value: familyId)
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    func createReward(_ reward: Reward) async throws -> Reward {
        try await client
            .from("rewards")
            .insert(reward, returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }

    func updateReward(_ reward: Reward) async throws -> Reward {
        try await client
            .from("rewards")
            .update(reward, returning: .representation)
            .eq("id", value: reward.id)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteReward(id: String) async throws {
        _ = try await client
            .from("rewards")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Redemptions

    func requestRedemption(rewardId: String, memberId: String) async throws -> RewardRedemption {
        try await client
            .from("reward_redemptions")
            .insert([
                "reward_id": rewardId,
                "member_id": memberId,
                "status": "requested",
                "requested_at": ISO8601DateFormatter().string(from: Date())
            ], returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }

    func setRedemptionStatus(id: String, status: String, decidedBy: String) async throws -> RewardRedemption {
        try await client
            .from("reward_redemptions")
            .update([
                "status": status,
                "decided_by": decidedBy,
                "decided_at": ISO8601DateFormatter().string(from: Date())
            ], returning: .representation)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
    }

    func fetchRedemptions(familyId: String) async throws -> [RewardRedemption] {
        try await client
            .from("reward_redemptions")
            .select()
            .eq("family_id", value: familyId)
            .order("requested_at", ascending: false)
            .execute()
            .value
    }

    // MARK: - Points ledger

    func addLedgerEntry(_ entry: PointsLedger) async throws -> PointsLedger {
        try await client
            .from("points_ledger")
            .insert(entry, returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }

    func fetchLedger(familyId: String, memberId: String) async throws -> [PointsLedger] {
        try await client
            .from("points_ledger")
            .select()
            .eq("family_id", value: familyId)
            .eq("member_id", value: memberId)
            .order("created_at", ascending: false)
            .execute()
            .value
    }
}
