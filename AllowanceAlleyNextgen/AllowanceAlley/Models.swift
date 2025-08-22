import Foundation

// MARK: - Core App Models

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

// Family Model
public struct Family: Identifiable, Codable, Equatable {
    public var id: String
    public var ownerId: String
    public var name: String
    public var createdAt: Date
    
    public init(
        id: String = UUID().uuidString,
        ownerId: String,
        name: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.ownerId = ownerId
        self.name = name
        self.createdAt = createdAt
    }
}

// Child Model
public struct Child: Identifiable, Codable, Equatable {
    public var id: String
    public var parentUserId: String
    public var name: String
    public var birthdate: Date?
    public var avatarURL: String?
    public var createdAt: Date
    
    public init(
        id: String = UUID().uuidString,
        parentUserId: String,
        name: String,
        birthdate: Date? = nil,
        avatarURL: String? = nil,
        createdAt: Date = Date()
    ) {
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

// Chore Model
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
    
    public init(
        id: String = UUID().uuidString,
        familyId: String,
        title: String,
        description: String? = nil,
        points: Int,
        requirePhoto: Bool = false,
        recurrence: String? = nil,
        parentUserId: String,
        createdAt: Date = Date()
    ) {
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

// Chore Assignment Model
public struct ChoreAssignment: Identifiable, Codable, Equatable {
    public var id: String
    public var choreId: String
    public var memberId: String
    public var dueDate: Date?
    public var createdAt: Date
    
    public init(
        id: String = UUID().uuidString,
        choreId: String,
        memberId: String,
        dueDate: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.choreId = choreId
        self.memberId = memberId
        self.dueDate = dueDate
        self.createdAt = createdAt
    }
}

// Chore Completion Model
public struct ChoreCompletion: Identifiable, Codable, Equatable {
    public var id: String
    public var assignmentId: String
    public var submittedBy: String?
    public var photoURL: String?
    public var status: CompletionStatus
    public var completedAt: Date?
    public var reviewedBy: String?
    public var reviewedAt: Date?
    
    public init(
        id: String = UUID().uuidString,
        assignmentId: String,
        submittedBy: String? = nil,
        photoURL: String? = nil,
        status: CompletionStatus = .pending,
        completedAt: Date? = nil,
        reviewedBy: String? = nil,
        reviewedAt: Date? = nil
    ) {
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

// Reward Model
public struct Reward: Identifiable, Codable, Equatable {
    public var id: String
    public var familyId: String
    public var name: String
    public var costPoints: Int
    public var createdAt: Date
    
    public init(
        id: String = UUID().uuidString,
        familyId: String,
        name: String,
        costPoints: Int,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.familyId = familyId
        self.name = name
        self.costPoints = costPoints
        self.createdAt = createdAt
    }
}

// Reward Redemption Model
public struct RewardRedemption: Identifiable, Codable, Equatable {
    public var id: String
    public var rewardId: String
    public var memberId: String
    public var status: RedemptionStatus
    public var requestedAt: Date?
    public var decidedBy: String?
    public var decidedAt: Date?
    
    public init(
        id: String = UUID().uuidString,
        rewardId: String,
        memberId: String,
        status: RedemptionStatus = .requested,
        requestedAt: Date? = nil,
        decidedBy: String? = nil,
        decidedAt: Date? = nil
    ) {
        self.id = id
        self.rewardId = rewardId
        self.memberId = memberId
        self.status = status
        self.requestedAt = requestedAt
        self.decidedBy = decidedBy
        self.decidedAt = decidedAt
    }
}

// Points Ledger Model
public struct PointsLedger: Identifiable, Codable, Equatable {
    public var id: String
    public var familyId: String
    public var memberId: String
    public var delta: Int
    public var reason: String?
    public var event: PointsEvent
    public var createdAt: Date
    
    public init(
        id: String = UUID().uuidString,
        familyId: String,
        memberId: String,
        delta: Int,
        reason: String? = nil,
        event: PointsEvent,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.familyId = familyId
        self.memberId = memberId
        self.delta = delta
        self.reason = reason
        self.event = event
        self.createdAt = createdAt
    }
}

// User Profile Model
public struct AppUser: Identifiable, Codable, Equatable {
    public var id: String
    public var role: UserRole
    public var email: String?
    public var displayName: String
    public var familyId: String?
    public var createdAt: Date
    
    public init(
        id: String = UUID().uuidString,
        role: UserRole,
        email: String? = nil,
        displayName: String,
        familyId: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.email = email
        self.displayName = displayName
        self.familyId = familyId
        self.createdAt = createdAt
    }
}

// Dashboard Summary Model
public struct DashboardSummary: Codable {
    public var todayAssigned = 0
    public var todayCompleted = 0
    public var thisWeekAssigned = 0
    public var thisWeekCompleted = 0
    public var pendingApprovals = 0
    public var childrenStats: [ChildStats] = []
    public var totalPointsEarned = 0
}

public struct ChildStats: Codable {
    public var childId: String
    public var displayName: String
    public var completedChores: Int = 0
    public var pendingChores: Int = 0
    public var weeklyPoints: Int = 0
    public var totalPoints: Int = 0
}

// MARK: - Helper Extensions

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
}
