import Foundation

// MARK: - Enums

public enum UserRole: String, Codable, CaseIterable {
    case parent = "parent"
    case child = "child"
}

public enum CompletionStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
}

public enum RedemptionStatus: String, Codable, CaseIterable {
    case requested = "requested"
    case approved = "approved"
    case rejected = "rejected"
    case fulfilled = "fulfilled"
}

public enum PointsEvent: String, Codable, CaseIterable {
    case choreCompleted = "chore_completed"
    case rewardRedeemed = "reward_redeemed"
    case bonus = "bonus"
    case penalty = "penalty"
}

// MARK: - Core Models

public struct Family: Identifiable, Codable, Equatable {
    public var id: String
    public var ownerId: String
    public var name: String
    public var createdAt: Date
    
    public init(id: String = UUID().uuidString, ownerId: String, name: String, createdAt: Date = Date()) {
        self.id = id
        self.ownerId = ownerId
        self.name = name
        self.createdAt = createdAt
    }
}

public struct Child: Identifiable, Codable, Equatable {
    public var id: String
    public var parentUserId: String
    public var name: String
    public var birthdate: Date?
    public var avatarURL: String?
    public var createdAt: Date
    
    public init(id: String = UUID().uuidString, parentUserId: String, name: String, birthdate: Date? = nil, avatarURL: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.parentUserId = parentUserId
        self.name = name
        self.birthdate = birthdate
        self.avatarURL = avatarURL
        self.createdAt = createdAt
    }
    
    public var age: Int? {
        guard let birthdate = birthdate else { return nil }
        return Calendar.current.dateComponents([.year], from: birthdate, to: Date()).year
    }
}

public struct Chore: Identifiable, Codable, Equatable {
    public var id: String
    public var familyId: String
    public var title: String
    public var description: String?
    public var points: Int
    public var requirePhoto: Bool
    public var recurrence: String?
    public var parentUserId: String
    public var createdAt: Date
    
    public init(id: String = UUID().uuidString, familyId: String, title: String, description: String? = nil, points: Int, requirePhoto: Bool = false, recurrence: String? = nil, parentUserId: String, createdAt: Date = Date()) {
        self.id = id
        self.familyId = familyId
        self.title = title
        self.description = description
        self.points = points
        self.requirePhoto = requirePhoto
        self.recurrence = recurrence
        self.parentUserId = parentUserId
        self.createdAt = createdAt
    }
}

public struct ChoreAssignment: Identifiable, Codable, Equatable {
    public var id: String
    public var choreId: String
    public var memberId: String
    public var dueDate: Date?
    public var createdAt: Date
    
    public init(id: String = UUID().uuidString, choreId: String, memberId: String, dueDate: Date? = nil, createdAt: Date = Date()) {
        self.id = id
        self.choreId = choreId
        self.memberId = memberId
        self.dueDate = dueDate
        self.createdAt = createdAt
    }
}

public struct ChoreCompletion: Identifiable, Codable, Equatable {
    public var id: String
    public var assignmentId: String
    public var submittedBy: String?
    public var photoURL: String?
    public var status: CompletionStatus
    public var completedAt: Date?
    public var reviewedBy: String?
    public var reviewedAt: Date?
    
    public init(id: String = UUID().uuidString, assignmentId: String, submittedBy: String? = nil, photoURL: String? = nil, status: CompletionStatus = .pending, completedAt: Date? = nil, reviewedBy: String? = nil, reviewedAt: Date? = nil) {
        self.id = id
        self.assignmentId = assignmentId
        self.submittedBy = submittedBy
        self.photoURL = photoURL
        self.status = status
        self.completedAt = completedAt
        self.reviewedBy = reviewedBy
        self.reviewedAt = reviewedAt
    }
}

public struct Reward: Identifiable, Codable, Equatable {
    public var id: String
    public var familyId: String
    public var name: String
    public var costPoints: Int
    public var createdAt: Date
    
    public init(id: String = UUID().uuidString, familyId: String, name: String, costPoints: Int, createdAt: Date = Date()) {
        self.id = id
        self.familyId = familyId
        self.name = name
        self.costPoints = costPoints
        self.createdAt = createdAt
    }
}

public struct RewardRedemption: Identifiable, Codable, Equatable {
    public var id: String
    public var rewardId: String
    public var memberId: String
    public var status: RedemptionStatus
    public var requestedAt: Date?
    public var decidedBy: String?
    public var decidedAt: Date?
    
    public init(id: String = UUID().uuidString, rewardId: String, memberId: String, status: RedemptionStatus = .requested, requestedAt: Date? = nil, decidedBy: String? = nil, decidedAt: Date? = nil) {
        self.id = id
        self.rewardId = rewardId
        self.memberId = memberId
        self.status = status
        self.requestedAt = requestedAt
        self.decidedBy = decidedBy
        self.decidedAt = decidedAt
    }
}

public struct PointsLedger: Identifiable, Codable, Equatable {
    public var id: String
    public var familyId: String
    public var memberId: String
    public var delta: Int
    public var reason: String?
    public var event: PointsEvent
    public var createdAt: Date
    
    public init(id: String = UUID().uuidString, familyId: String, memberId: String, delta: Int, reason: String? = nil, event: PointsEvent, createdAt: Date = Date()) {
        self.id = id
        self.familyId = familyId
        self.memberId = memberId
        self.delta = delta
        self.reason = reason
        self.event = event
        self.createdAt = createdAt
    }
}

public struct AppUser: Identifiable, Codable, Equatable {
    public var id: String
    public var role: UserRole
    public var email: String?
    public var displayName: String
    public var familyId: String?
    public var createdAt: Date
    
    public init(id: String = UUID().uuidString, role: UserRole, email: String? = nil, displayName: String, familyId: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.role = role
        self.email = email
        self.displayName = displayName
        self.familyId = familyId
        self.createdAt = createdAt
    }
}

// MARK: - Dashboard Models

public struct DashboardSummary: Codable {
    public var todayAssigned = 0
    public var todayCompleted = 0
    public var thisWeekAssigned = 0
    public var thisWeekCompleted = 0
    public var pendingApprovals = 0
    public var childrenStats: [ChildStats] = []
    public var totalPointsEarned = 0
    
    public init() {}
}

public struct ChildStats: Codable {
    public var childId: String
    public var displayName: String
    public var completedChores: Int = 0
    public var pendingChores: Int = 0
    public var weeklyPoints: Int = 0
    public var totalPoints: Int = 0
    
    public init(childId: String, displayName: String) {
        self.childId = childId
        self.displayName = displayName
    }
}

// MARK: - Family Member Model

public struct FamilyMember: Identifiable, Codable, Equatable {
    public var id: String
    public var familyId: String
    public var userId: String?
    public var childName: String?
    public var age: Int?
    public var role: UserRole
    public var createdAt: Date?
    
    public init(id: String = UUID().uuidString, familyId: String, userId: String? = nil, childName: String? = nil, age: Int? = nil, role: UserRole, createdAt: Date? = nil) {
        self.id = id
        self.familyId = familyId
        self.userId = userId
        self.childName = childName
        self.age = age
        self.role = role
        self.createdAt = createdAt
    }
}

// MARK: - Codable Extensions for Database Mapping

extension Family {
    enum CodingKeys: String, CodingKey {
        case id, name
        case ownerId = "owner_id"
        case createdAt = "created_at"
    }
}

extension Child {
    enum CodingKeys: String, CodingKey {
        case id, name, birthdate
        case parentUserId = "parent_user_id"
        case avatarURL = "avatar_url"
        case createdAt = "created_at"
    }
}

extension Chore {
    enum CodingKeys: String, CodingKey {
        case id, title, description, points, recurrence
        case familyId = "family_id"
        case requirePhoto = "require_photo"
        case parentUserId = "parent_user_id"
        case createdAt = "created_at"
    }
}

extension ChoreAssignment {
    enum CodingKeys: String, CodingKey {
        case id
        case choreId = "chore_id"
        case memberId = "member_id"
        case dueDate = "due_date"
        case createdAt = "created_at"
    }
}

extension ChoreCompletion {
    enum CodingKeys: String, CodingKey {
        case id, status
        case assignmentId = "assignment_id"
        case submittedBy = "submitted_by"
        case photoURL = "photo_url"
        case completedAt = "completed_at"
        case reviewedBy = "reviewed_by"
        case reviewedAt = "reviewed_at"
    }
}

extension Reward {
    enum CodingKeys: String, CodingKey {
        case id, name
        case familyId = "family_id"
        case costPoints = "cost_points"
        case createdAt = "created_at"
    }
}

extension RewardRedemption {
    enum CodingKeys: String, CodingKey {
        case id, status
        case rewardId = "reward_id"
        case memberId = "member_id"
        case requestedAt = "requested_at"
        case decidedBy = "decided_by"
        case decidedAt = "decided_at"
    }
}

extension PointsLedger {
    enum CodingKeys: String, CodingKey {
        case id, delta, reason, event
        case familyId = "family_id"
        case memberId = "member_id"
        case createdAt = "created_at"
    }
}

extension AppUser {
    enum CodingKeys: String, CodingKey {
        case id, role, email
        case displayName = "display_name"
        case familyId = "family_id"
        case createdAt = "created_at"
    }
}

extension FamilyMember {
    enum CodingKeys: String, CodingKey {
        case id, role, age
        case familyId = "family_id"
        case userId = "user_id"
        case childName = "child_name"
        case createdAt = "created_at"
    }
}

// MARK: - Date Extensions

public extension Date {
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    func ISO8601String() -> String {
        ISO8601DateFormatter().string(from: self)
    }
}
