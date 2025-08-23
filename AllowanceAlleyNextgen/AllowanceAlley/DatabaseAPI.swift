
// DatabaseAPI.swift — fixed generics + AnyEncodable payloads
import Foundation
import Supabase

struct DatabaseAPI {
    static let shared = DatabaseAPI()
    private let client = AppSupabase.shared.client
    private init() {}

    // MARK: - Profiles & Roles

    struct UserRoleInfo: Codable {
        let familyId: String?
        let userId: String?
        let role: UserRole
        enum CodingKeys: String, CodingKey {
            case familyId = "family_id"
            case userId = "user_id"
            case role
        }
    }

    func fetchProfile(userId: String) async throws -> Profile? {
        let rows: [Profile] = try await client
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    func fetchUserRole(userId: String) async throws -> (familyId: String?, role: UserRole)? {
        let rows: [UserRoleInfo] = try await client
            .from("v_user_family_roles")
            .select()
            .eq("user_id", value: userId)
            .limit(1)
            .execute()
            .value
        if let r = rows.first { return (r.familyId, r.role) }
        if let fam = try await fetchFamilyByOwner(ownerId: userId) { return (fam.id, .parent) }
        return nil
    }

    // MARK: - Families

    func createFamily(name: String, ownerId: String) async throws -> Family {
        let payload: [String: AnyEncodable] = [
            "name": AnyEncodable(name),
            "owner_id": AnyEncodable(ownerId)
        ]
        let row: Family = try await client
            .from("families")
            .insert(payload, returning: .representation)
            .select()
            .single()
            .execute()
            .value
        return row
    }

    func fetchFamilyByOwner(ownerId: String) async throws -> Family? {
        let rows: [Family] = try await client
            .from("families")
            .select()
            .eq("owner_id", value: ownerId)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    func fetchFamily(id: String) async throws -> Family? {
        let rows: [Family] = try await client
            .from("families")
            .select()
            .eq("id", value: id)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    // MARK: - Family Members

    func listFamilyMembers(familyId: String, role: UserRole? = nil) async throws -> [FamilyMember] {
        var query = client.from("family_members").select().eq("family_id", value: familyId)
        if let role { query = query.eq("role", value: role.rawValue) }
        let rows: [FamilyMember] = try await query.order("created_at", ascending: true).execute().value
        return rows
    }

    func createChildMember(familyId: String, childName: String, age: Int?) async throws -> FamilyMember {
        var payload: [String: AnyEncodable] = [
            "family_id": AnyEncodable(familyId),
            "child_name": AnyEncodable(childName),
            "role": AnyEncodable(UserRole.child.rawValue)
        ]
        if let age { payload["age"] = AnyEncodable(age) }
        let row: FamilyMember = try await client
            .from("family_members")
            .insert(payload, returning: .representation)
            .select()
            .single()
            .execute()
            .value
        return row
    }

    // MARK: - Children (optional)

    func createChildProfile(parentUserId: String, name: String, birthdate: Date? = nil, avatarURL: String? = nil) async throws -> Child {
        var payload: [String: AnyEncodable] = [
            "parent_user_id": AnyEncodable(parentUserId),
            "name": AnyEncodable(name)
        ]
        if let birthdate {
            let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
            payload["birthdate"] = AnyEncodable(df.string(from: birthdate))
        }
        if let avatarURL { payload["avatar_url"] = AnyEncodable(avatarURL) }
        let row: Child = try await client
            .from("children")
            .insert(payload, returning: .representation)
            .select()
            .single()
            .execute()
            .value
        return row
    }

    func listChildrenOfParent(parentUserId: String) async throws -> [Child] {
        let rows: [Child] = try await client
            .from("children")
            .select()
            .eq("parent_user_id", value: parentUserId)
            .order("created_at", ascending: true)
            .execute()
            .value
        return rows
    }

    // MARK: - Chores

    func fetchChores(familyId: String) async throws -> [Chore] {
        let rows: [Chore] = try await client
            .from("chores")
            .select()
            .eq("family_id", value: familyId)
            .order("created_at", ascending: true)
            .execute()
            .value
        return rows
    }

    func createChore(familyId: String, title: String, description: String?, points: Int, requirePhoto: Bool, recurrence: String?, parentUserId: String) async throws -> Chore {
        var payload: [String: AnyEncodable] = [
            "family_id": AnyEncodable(familyId),
            "title": AnyEncodable(title),
            "points": AnyEncodable(points),
            "require_photo": AnyEncodable(requirePhoto),
            "parent_user_id": AnyEncodable(parentUserId)
        ]
        if let description { payload["description"] = AnyEncodable(description) }
        if let recurrence { payload["recurrence"] = AnyEncodable(recurrence) }
        let row: Chore = try await client
            .from("chores")
            .insert(payload, returning: .representation)
            .select()
            .single()
            .execute()
            .value
        return row
    }

    // MARK: - Assignments

    private func dateOnly(_ d: Date) -> String {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .iso8601)
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: d)
    }

    func assignChore(choreId: String, memberId: String, due: Date?) async throws -> ChoreAssignment {
        var payload: [String: AnyEncodable] = [
            "chore_id": AnyEncodable(choreId),
            "member_id": AnyEncodable(memberId)
        ]
        if let due { payload["due_date"] = AnyEncodable(dateOnly(due)) }
        let row: ChoreAssignment = try await client
            .from("chore_assignments")
            .insert(payload, returning: .representation)
            .select()
            .single()
            .execute()
            .value
        return row
    }

    func fetchAssignmentsForFamily(familyId: String) async throws -> [ChoreAssignment] {
        let members = try await listFamilyMembers(familyId: familyId)
        let memberIds = members.map { $0.id }
        if memberIds.isEmpty { return [] }
        let rows: [ChoreAssignment] = try await client
            .from("chore_assignments")
            .select()
            .in("member_id", values: memberIds)
            .order("created_at", ascending: false)
            .execute()
            .value
        return rows
    }

    // MARK: - Completions

    func submitCompletion(assignmentId: String, submittedBy: String?, photoURL: String?) async throws -> ChoreCompletion {
        var payload: [String: AnyEncodable] = [
            "assignment_id": AnyEncodable(assignmentId),
            "status": AnyEncodable(CompletionStatus.pending.rawValue)
        ]
        if let submittedBy { payload["submitted_by"] = AnyEncodable(submittedBy) }
        if let photoURL { payload["photo_url"] = AnyEncodable(photoURL) }
        let row: ChoreCompletion = try await client
            .from("chore_completions")
            .insert(payload, returning: .representation)
            .select()
            .single()
            .execute()
            .value
        return row
    }

    func reviewCompletion(id: String, status: CompletionStatus, reviewedBy: String) async throws -> ChoreCompletion {
        let payload: [String: AnyEncodable] = [
            "status": AnyEncodable(status.rawValue),
            "reviewed_by": AnyEncodable(reviewedBy),
            "reviewed_at": AnyEncodable(ISO8601DateFormatter().string(from: Date()))
        ]
        let row: ChoreCompletion = try await client
            .from("chore_completions")
            .update(payload, returning: .representation)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
        return row
    }

    func fetchCompletionsForFamily(familyId: String) async throws -> [ChoreCompletion] {
        let assignments = try await fetchAssignmentsForFamily(familyId: familyId)
        let ids = assignments.map { $0.id }
        if ids.isEmpty { return [] }
        let rows: [ChoreCompletion] = try await client
            .from("chore_completions")
            .select()
            .in("assignment_id", values: ids)
            .order("completed_at", ascending: false)
            .execute()
            .value
        return rows
    }

    // MARK: - Rewards & Redemptions

    func fetchRewards(familyId: String) async throws -> [Reward] {
        let rows: [Reward] = try await client
            .from("rewards")
            .select()
            .eq("family_id", value: familyId)
            .order("created_at", ascending: true)
            .execute()
            .value
        return rows
    }

    func createReward(familyId: String, name: String, costPoints: Int) async throws -> Reward {
        let payload: [String: AnyEncodable] = [
            "family_id": AnyEncodable(familyId),
            "name": AnyEncodable(name),
            "cost_points": AnyEncodable(costPoints)
        ]
        let row: Reward = try await client
            .from("rewards")
            .insert(payload, returning: .representation)
            .select()
            .single()
            .execute()
            .value
        return row
    }

    func updateReward(reward: Reward) async throws -> Reward {
        let row: Reward = try await client
            .from("rewards")
            .update(reward, returning: .representation)
            .eq("id", value: reward.id)
            .select()
            .single()
            .execute()
            .value
        return row
    }

    func deleteReward(id: String) async throws {
        _ = try await client
            .from("rewards")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    func requestRedemption(rewardId: String, memberId: String) async throws -> RewardRedemption {
        let payload: [String: AnyEncodable] = [
            "reward_id": AnyEncodable(rewardId),
            "member_id": AnyEncodable(memberId)
        ]
        let row: RewardRedemption = try await client
            .from("reward_redemptions")
            .insert(payload, returning: .representation)
            .select()
            .single()
            .execute()
            .value
        return row
    }

    func fetchRedemptionsForFamily(familyId: String) async throws -> [RewardRedemption] {
        let members = try await listFamilyMembers(familyId: familyId)
        let ids = members.map { $0.id }
        if ids.isEmpty { return [] }
        let rows: [RewardRedemption] = try await client
            .from("reward_redemptions")
            .select()
            .in("member_id", values: ids)
            .order("requested_at", ascending: false)
            .execute()
            .value
        return rows
    }

    func setRedemptionStatus(id: String, status: RedemptionStatus, decidedBy: String) async throws -> RewardRedemption {
        let payload: [String: AnyEncodable] = [
            "status": AnyEncodable(status.rawValue),
            "decided_by": AnyEncodable(decidedBy),
            "decided_at": AnyEncodable(ISO8601DateFormatter().string(from: Date()))
        ]
        let row: RewardRedemption = try await client
            .from("reward_redemptions")
            .update(payload, returning: .representation)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
        return row
    }

    // MARK: - Points Ledger

    func fetchLedger(familyId: String, memberId: String? = nil) async throws -> [PointsLedger] {
        var q = client.from("points_ledger").select().eq("family_id", value: familyId)
        if let memberId { q = q.eq("member_id", value: memberId) }
        let rows: [PointsLedger] = try await q.order("created_at", ascending: false).execute().value
        return rows
    }

    func addLedgerEntry(_ entry: PointsLedger) async throws -> PointsLedger {
        let row: PointsLedger = try await client
            .from("points_ledger")
            .insert(entry, returning: .representation)
            .select()
            .single()
            .execute()
            .value
        return row
    }
}
