import Foundation
import Supabase

final class DatabaseAPI {
    static let shared = DatabaseAPI()
    private let client = AppSupabase.shared.client
    private init() {}
    
    func createFamily(_ family: Family) async throws -> Family {
        let res: [Family] = try await client
            .from("families")
            .insert([
                "id": family.id,
                "owner_id": family.ownerId,
                "name": family.name
            ], returning: .representation)
            .select()
            .execute()
            .value
        guard let created = res.first else { throw NSError(domain: "InsertFailed", code: 1) }
        return created
    }
    
    func fetchFamily(id: String) async throws -> Family? {
        let res: [Family] = try await client
            .from("families")
            .select()
            .eq("id", value: id)
            .execute()
            .value
        return res.first
    }
    
    func createChild(_ child: Child) async throws -> Child {
        let res: [Child] = try await client
            .from("children")
            .insert([
                "id": child.id,
                "parent_user_id": child.parentUserId,
                "name": child.name,
                "birthdate": child.birthdate?.ISO8601String(),
                "avatar_url": child.avatarURL
            ], returning: .representation)
            .select()
            .execute()
            .value
        guard let created = res.first else { throw NSError(domain: "InsertFailed", code: 1) }
        return created
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

final class StorageAPI {
    static let shared = StorageAPI()
    private let client = AppSupabase.shared.client
    private init() {}
    
    func uploadImage(_ data: Data, bucket: String, path: String) async throws -> String {
        try await client.storage.from(bucket).upload(path: path, file: data)
        let publicURL = try client.storage.from(bucket).getPublicURL(path: path)
        return publicURL.absoluteString
    }
    
    func downloadImage(bucket: String, path: String) async throws -> Data {
        try await client.storage.from(bucket).download(path: path)
    }
}
