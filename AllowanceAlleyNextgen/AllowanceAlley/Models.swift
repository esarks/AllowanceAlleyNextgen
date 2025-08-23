
import Foundation

// MARK: - Enums

public enum UserRole: String, Codable, CaseIterable {
    case parent, child
}

public enum CompletionStatus: String, Codable, CaseIterable {
    case pending, approved, rejected
}

public enum RedemptionStatus: String, Codable, CaseIterable {
    case requested, approved, rejected
}

// MARK: - Users

public struct AppUser: Identifiable, Codable, Equatable {
    public var id: String                   // auth user id
    public var email: String?
    public var role: UserRole               // from v_user_family_roles or default .parent
    public var familyId: String?            // fetched via families.owner_id or v_user_family_roles
}

// MARK: - Profiles (DB: profiles)

public struct Profile: Identifiable, Codable, Equatable {
    public var id: String                   // equals auth user id
    public var displayName: String?
    public var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case createdAt = "created_at"
    }
}

// MARK: - Families (DB: families)

public struct Family: Identifiable, Codable, Equatable {
    public var id: String
    public var ownerId: String
    public var name: String
    public var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case ownerId = "owner_id"
        case name
        case createdAt = "created_at"
    }
}

// MARK: - Family Members (DB: family_members)

public struct FamilyMember: Identifiable, Codable, Equatable {
    public var id: String
    public var familyId: String
    public var userId: String?
    public var childName: String?
    public var age: Int?
    public var role: UserRole
    public var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case userId = "user_id"
        case childName = "child_name"
        case age
        case role
        case createdAt = "created_at"
    }
}

// MARK: - Children (DB: children) — optional profile table for kids without accounts

public struct Child: Identifiable, Codable, Equatable {
    public var id: String
    public var parentUserId: String
    public var name: String
    public var birthdate: Date?
    public var avatarURL: String?
    public var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case parentUserId = "parent_user_id"
        case name
        case birthdate
        case avatarURL = "avatar_url"
        case createdAt = "created_at"
    }
}

// MARK: - Chores (DB: chores)

public struct Chore: Identifiable, Codable, Equatable {
    public var id: String
    public var familyId: String
    public var title: String
    public var description: String?
    public var points: Int
    public var requirePhoto: Bool
    public var recurrence: String?
    public var parentUserId: String
    public var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case title
        case description
        case points
        case requirePhoto = "require_photo"
        case recurrence
        case parentUserId = "parent_user_id"
        case createdAt = "created_at"
    }
}

// MARK: - Chore Assignments (DB: chore_assignments)

public struct ChoreAssignment: Identifiable, Codable, Equatable {
    public var id: String
    public var choreId: String
    public var memberId: String
    public var dueDate: String?            // DB is 'date' (YYYY-MM-DD)

    public var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case choreId = "chore_id"
        case memberId = "member_id"
        case dueDate = "due_date"
        case createdAt = "created_at"
    }

    public var dueDateAsDate: Date? {
        guard let dueDate else { return nil }
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .iso8601)
        df.dateFormat = "yyyy-MM-dd"
        return df.date(from: dueDate)
    }
}

// MARK: - Completions (DB: chore_completions)

public struct ChoreCompletion: Identifiable, Codable, Equatable {
    public var id: String
    public var assignmentId: String
    public var submittedBy: String?
    public var photoURL: String?
    public var status: CompletionStatus
    public var completedAt: Date?
    public var reviewedBy: String?
    public var reviewedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case assignmentId = "assignment_id"
        case submittedBy = "submitted_by"
        case photoURL = "photo_url"
        case status
        case completedAt = "completed_at"
        case reviewedBy = "reviewed_by"
        case reviewedAt = "reviewed_at"
    }
}

// MARK: - Rewards (DB: rewards)

public struct Reward: Identifiable, Codable, Equatable {
    public var id: String
    public var familyId: String
    public var name: String
    public var costPoints: Int
    public var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case name
        case costPoints = "cost_points"
        case createdAt = "created_at"
    }
}

// MARK: - Reward Redemptions (DB: reward_redemptions)

public struct RewardRedemption: Identifiable, Codable, Equatable {
    public var id: String
    public var rewardId: String
    public var memberId: String
    public var status: RedemptionStatus
    public var requestedAt: Date?
    public var decidedBy: String?
    public var decidedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case rewardId = "reward_id"
        case memberId = "member_id"
        case status
        case requestedAt = "requested_at"
        case decidedBy = "decided_by"
        case decidedAt = "decided_at"
    }
}

// MARK: - Points Ledger (DB: points_ledger)

public struct PointsLedger: Identifiable, Codable, Equatable {
    public var id: String
    public var familyId: String
    public var memberId: String
    public var delta: Int
    public var reason: String?
    public var event: String               // e.g., 'chore_completed', 'reward_redeemed'
    public var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case memberId = "member_id"
        case delta
        case reason
        case event
        case createdAt = "created_at"
    }
}
