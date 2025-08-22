//
//  Models.swift
//  AllowanceAlley
//

import Foundation
import SwiftUI

// MARK: - User Models

enum UserRole: String, CaseIterable, Codable {
    case parent = "Parent"
    case child = "Child"
}

struct AppUser: Identifiable, Codable {
    let id: String
    var role: UserRole
    var email: String?
    var childPIN: String?
    var displayName: String
    var avatarURL: String?
    var familyId: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String = UUID().uuidString,
         role: UserRole,
         email: String? = nil,
         childPIN: String? = nil,
         displayName: String,
         avatarURL: String? = nil,
         familyId: String? = nil) {
        self.id = id
        self.role = role
        self.email = email
        self.childPIN = childPIN
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.familyId = familyId
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Family Models

struct Family: Identifiable, Codable {
    let id: String
    var name: String
    var ownerUserId: String
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String = UUID().uuidString,
         name: String,
         ownerUserId: String) {
        self.id = id
        self.name = name
        self.ownerUserId = ownerUserId
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Chore Models

enum RecurrenceRule: String, CaseIterable, Codable {
    case none = "none"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    
    var displayName: String {
        switch self {
        case .none: return "One-time"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}

struct Chore: Identifiable, Codable {
    let id: String
    var familyId: String
    var title: String
    var description: String?
    var points: Int
    var valueCents: Int?
    var requiresPhoto: Bool
    var recurrenceRule: RecurrenceRule
    var createdBy: String
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String = UUID().uuidString,
         familyId: String,
         title: String,
         description: String? = nil,
         points: Int,
         valueCents: Int? = nil,
         requiresPhoto: Bool = false,
         recurrenceRule: RecurrenceRule = .none,
         createdBy: String) {
        self.id = id
        self.familyId = familyId
        self.title = title
        self.description = description
        self.points = points
        self.valueCents = valueCents
        self.requiresPhoto = requiresPhoto
        self.recurrenceRule = recurrenceRule
        self.createdBy = createdBy
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum ChoreInstanceStatus: String, CaseIterable, Codable {
    case assigned = "Assigned"
    case completed = "Completed"
    case approved = "Approved"
    case rejected = "Rejected"
    
    var color: Color {
        switch self {
        case .assigned: return .orange
        case .completed: return .blue
        case .approved: return .green
        case .rejected: return .red
        }
    }
    
    var systemImage: String {
        switch self {
        case .assigned: return "clock"
        case .completed: return "checkmark.circle"
        case .approved: return "checkmark.circle.fill"
        case .rejected: return "x.circle.fill"
        }
    }
}

struct ChoreInstance: Identifiable, Codable {
    let id: String
    var choreId: String
    var dueAt: Date
    var assigneeChildId: String
    var status: ChoreInstanceStatus
    var photoURL: String?
    var completedAt: Date?
    var approvedAt: Date?
    var createdAt: Date
    var updatedAt: Date
    
    // Computed properties
    var isOverdue: Bool {
        status == .assigned && dueAt < Date()
    }
    
    var isDueSoon: Bool {
        status == .assigned && dueAt.timeIntervalSinceNow <= 3600 && dueAt.timeIntervalSinceNow > 0
    }
    
    init(id: String = UUID().uuidString,
         choreId: String,
         dueAt: Date,
         assigneeChildId: String,
         status: ChoreInstanceStatus = .assigned) {
        self.id = id
        self.choreId = choreId
        self.dueAt = dueAt
        self.assigneeChildId = assigneeChildId
        self.status = status
        self.photoURL = nil
        self.completedAt = nil
        self.approvedAt = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Rewards Models

struct Reward: Identifiable, Codable {
    let id: String
    var familyId: String
    var title: String
    var description: String?
    var costPoints: Int
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String = UUID().uuidString,
         familyId: String,
         title: String,
         description: String? = nil,
         costPoints: Int,
         isActive: Bool = true) {
        self.id = id
        self.familyId = familyId
        self.title = title
        self.description = description
        self.costPoints = costPoints
        self.isActive = isActive
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum RedemptionStatus: String, CaseIterable, Codable {
    case requested = "Requested"
    case approved = "Approved"
    case rejected = "Rejected"
    case fulfilled = "Fulfilled"
    
    var color: Color {
        switch self {
        case .requested: return .orange
        case .approved: return .blue
        case .rejected: return .red
        case .fulfilled: return .green
        }
    }
}

struct Redemption: Identifiable, Codable {
    let id: String
    var rewardId: String
    var childId: String
    var status: RedemptionStatus
    var requestedAt: Date
    var decidedAt: Date?
    var fulfilledAt: Date?
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String = UUID().uuidString,
         rewardId: String,
         childId: String,
         status: RedemptionStatus = .requested) {
        self.id = id
        self.rewardId = rewardId
        self.childId = childId
        self.status = status
        self.requestedAt = Date()
        self.decidedAt = nil
        self.fulfilledAt = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Points & Ledger Models

struct PointsLedger: Identifiable, Codable {
    let id: String
    var childId: String
    var deltaPoints: Int
    var reason: String
    var relatedId: String?
    var createdAt: Date
    
    init(id: String = UUID().uuidString,
         childId: String,
         deltaPoints: Int,
         reason: String,
         relatedId: String? = nil) {
        self.id = id
        self.childId = childId
        self.deltaPoints = deltaPoints
        self.reason = reason
        self.relatedId = relatedId
        self.createdAt = Date()
    }
}

// MARK: - Settings Models

struct NotificationPref: Identifiable, Codable {
    let id: String
    var userId: String
    var dueSoonMinutesBefore: Int
    var allowReminders: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String = UUID().uuidString,
         userId: String,
         dueSoonMinutesBefore: Int = 60,
         allowReminders: Bool = true) {
        self.id = id
        self.userId = userId
        self.dueSoonMinutesBefore = dueSoonMinutesBefore
        self.allowReminders = allowReminders
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Audit Models

struct AuditLog: Identifiable, Codable {
    let id: String
    var familyId: String
    var actorUserId: String
    var action: String
    var entityType: String
    var entityId: String
    var timestamp: Date
    var metadataJSON: String?
    
    init(id: String = UUID().uuidString,
         familyId: String,
         actorUserId: String,
         action: String,
         entityType: String,
         entityId: String,
         metadataJSON: String? = nil) {
        self.id = id
        self.familyId = familyId
        self.actorUserId = actorUserId
        self.action = action
        self.entityType = entityType
        self.entityId = entityId
        self.timestamp = Date()
        self.metadataJSON = metadataJSON
    }
}

// MARK: - Sync Models

enum SyncState: String, CaseIterable {
    case pending = "pending"
    case syncing = "syncing"
    case synced = "synced"
    case failed = "failed"
}

// MARK: - Dashboard Models

struct DashboardSummary {
    var todayAssigned: Int = 0
    var todayCompleted: Int = 0
    var thisWeekAssigned: Int = 0
    var thisWeekCompleted: Int = 0
    var totalPointsEarned: Int = 0
    var pendingApprovals: Int = 0
    var childrenStats: [ChildStats] = []
}

struct ChildStats {
    let childId: String
    let displayName: String
    var totalPoints: Int = 0
    var weeklyPoints: Int = 0
    var completedChores: Int = 0
    var pendingChores: Int = 0
}

// MARK: - Extensions

extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
    
    func adding(weeks: Int) -> Date {
        Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: self) ?? self
    }
    
    func adding(months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }
}