import Foundation
import Supabase

final class DatabaseAPI {
    static let shared = DatabaseAPI()
    private let client = AppSupabase.shared.client
    private init() {}
    
    // Families
    func createFamily(_ family: Family) async throws -> Family {
        let inserted: [Family] = try await client
            .from("families")
            .insert([
                "id": family.id,
                "owner_id": family.ownerId,
                "name": family.name,
                "created_at": family.createdAt.ISO8601String()
            ], returning: .representation)
            .select()
            .execute()
            .value
        
        guard let first = inserted.first else {
            throw DatabaseError.insertFailed
        }
        return first
    }
    
    func fetchFamily(id: String) async throws -> Family? {
        let rows: [Family] = try await client
            .from("families")
            .select()
            .eq("id", value: id)
            .execute()
            .value
        return rows.first
    }
    
    // Children
    func createChild(_ child: Child) async throws -> Child {
        let rows: [Child] = try await client
            .from("children")
            .insert([
                "id": child.id,
                "parent_user_id": child.parentUserId,
                "name": child.name,
                "birthdate": child.birthdate?.ISO8601String(),
                "avatar_url": child.avatarURL,
                "created_at": child.createdAt.ISO8601String()
            ], returning: .representation)
            .select()
            .execute()
            .value
        
        guard let first = rows.first else {
            throw DatabaseError.insertFailed
        }
        return first
    }
    
    func fetchChildren(parentUserId: String) async throws -> [Child] {
        try await client
            .from("children")
            .select()
            .eq("parent_user_id", value: parentUserId)
            .execute()
            .value
    }
}

enum DatabaseError: LocalizedError {
    case insertFailed
    case notFound
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .insertFailed:
            return "Failed to insert data"
        case .notFound:
            return "Data not found"
        case .invalidData:
            return "Invalid data format"
        }
    }
}
