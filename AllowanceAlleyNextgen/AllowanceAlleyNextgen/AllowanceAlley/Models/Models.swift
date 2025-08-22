import Foundation

// MARK: - Core App Models (authoritative)

public enum UserRole: String, Codable, CaseIterable {
    case parent = "Parent"
    case child  = "Child"
}

public struct AppUser: Identifiable, Codable, Equatable {
    public var id: String
    public var role: UserRole
    public var email: String?
    public var childPIN: String?
    public var displayName: String
    public var avatarURL: String?
    public var familyId: String?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: String = UUID().uuidString,
        role: UserRole,
        email: String? = nil,
        childPIN: String? = nil,
        displayName: String,
        avatarURL: String? = nil,
        familyId: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.email = email
        self.childPIN = childPIN
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.familyId = familyId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Rewards Domain

public struct Reward: Identifiable, Codable, Equatable {
    public var id: String
    public var familyId: String
    public var title: String
    public var description: String?
    public var costPoints: Int
    public var isActive: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: String = UUID().uuidString,
        familyId: String,
        title: String,
        description: String? = nil,
        costPoints: Int,
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.familyId = familyId
        self.title = title
        self.description = description
        self.costPoints = costPoints
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public enum RedemptionStatus: String, Codable, CaseIterable {
    case requested = "Requested"
    case approved  = "Approved"
    case rejected  = "Rejected"
    case fulfilled = "Fulfilled"
}

public struct Redemption: Identifiable, Codable, Equatable {
    public var id: String
    public var rewardId: String
    public var childId: String
    public var status: RedemptionStatus
    public var requestedAt: Date
    public var decidedAt: Date?
    public var fulfilledAt: Date?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: String = UUID().uuidString,
        rewardId: String,
        childId: String,
        status: RedemptionStatus = .requested,
        requestedAt: Date = Date(),
        decidedAt: Date? = nil,
        fulfilledAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.rewardId = rewardId
        self.childId = childId
        self.status = status
        self.requestedAt = requestedAt
        self.decidedAt = decidedAt
        self.fulfilledAt = fulfilledAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct PointsLedger: Identifiable, Codable, Equatable {
    public var id: String
    public var childId: String
    public var deltaPoints: Int
    public var reason: String
    public var relatedId: String?
    public var createdAt: Date

    public init(
        id: String = UUID().uuidString,
        childId: String,
        deltaPoints: Int,
        reason: String,
        relatedId: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.childId = childId
        self.deltaPoints = deltaPoints
        self.reason = reason
        self.relatedId = relatedId
        self.createdAt = createdAt
    }
}

// MARK: - Notifications Domain

public struct NotificationPref: Identifiable, Codable, Equatable {
    public var id: String
    public var userId: String
    public var dueSoonMinutesBefore: Int
    public var allowReminders: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: String = UUID().uuidString,
        userId: String,
        dueSoonMinutesBefore: Int = 60,
        allowReminders: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.dueSoonMinutesBefore = dueSoonMinutesBefore
        self.allowReminders = allowReminders
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Small helpers

public extension Date {
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
}
