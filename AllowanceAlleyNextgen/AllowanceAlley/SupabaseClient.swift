import Foundation
import Supabase

final class SupabaseClient {
    static let shared = SupabaseClient()
    
    let client: SupabaseClient
    
    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: AppConfig.supabaseURL)!,
            supabaseKey: AppConfig.supabaseAnonKey
        )
    }
    
    // MARK: - Authentication
    
    func signUp(email: String, password: String) async throws -> AuthResponse {
        return try await client.auth.signUp(email: email, password: password)
    }
    
    func signIn(email: String, password: String) async throws -> AuthResponse {
        return try await client.auth.signIn(email: email, password: password)
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    func getCurrentSession() async throws -> Session? {
        return try await client.auth.session
    }
    
    func getCurrentUser() async throws -> User? {
        return try await client.auth.user
    }
    
    // MARK: - Database Operations
    
    func createFamily(_ family: Family) async throws -> Family {
        let response: [Family] = try await client.database
            .from("families")
            .insert([
                "id": family.id,
                "owner_id": family.ownerId,
                "name": family.name
            ])
            .select()
            .execute()
            .value
        
        guard let created = response.first else {
            throw SupabaseError.insertFailed
        }
        return created
    }
    
    func fetchFamily(id: String) async throws -> Family? {
        let response: [Family] = try await client.database
            .from("families")
            .select()
            .eq("id", value: id)
            .execute()
            .value
        
        return response.first
    }
    
    func createChild(_ child: Child) async throws -> Child {
        let response: [Child] = try await client.database
            .from("children")
            .insert([
                "id": child.id,
                "parent_user_id": child.parentUserId,
                "name": child.name,
                "birthdate": child.birthdate?.ISO8601String(),
                "avatar_url": child.avatarURL
            ])
            .select()
            .execute()
            .value
        
        guard let created = response.first else {
            throw SupabaseError.insertFailed
        }
        return created
    }
    
    func fetchChildren(parentUserId: String) async throws -> [Child] {
        let response: [Child] = try await client.database
            .from("children")
            .select()
            .eq("parent_user_id", value: parentUserId)
            .execute()
            .value
        
        return response
    }
    
    // MARK: - Storage Operations
    
    func uploadImage(_ data: Data, bucket: String, path: String) async throws -> String {
        try await client.storage
            .from(bucket)
            .upload(path: path, file: data)
        
        let publicURL = try client.storage
            .from(bucket)
            .getPublicURL(path: path)
        
        return publicURL.absoluteString
    }
    
    func downloadImage(bucket: String, path: String) async throws -> Data {
        return try await client.storage
            .from(bucket)
            .download(path: path)
    }
}

enum SupabaseError: LocalizedError {
    case insertFailed
    case fetchFailed
    case uploadFailed
    case downloadFailed
    
    var errorDescription: String? {
        switch self {
        case .insertFailed:
            return "Failed to insert data"
        case .fetchFailed:
            return "Failed to fetch data"
        case .uploadFailed:
            return "Failed to upload file"
        case .downloadFailed:
            return "Failed to download file"
        }
    }
}
