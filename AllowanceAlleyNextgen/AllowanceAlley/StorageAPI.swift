import Foundation
import Supabase

// Keep ONE definition of StorageAPI in the project.
final class StorageAPI {
    static let shared = StorageAPI()
    private let client = AppSupabase.shared.client
    private init() {}
    
    @discardableResult
    func uploadImage(_ data: Data, bucket: String, path: String) async throws -> String {
        // Upload
        try await client.storage.from(bucket).upload(path: path, file: data)
        // Get a public URL
        let publicURL = try client.storage.from(bucket).getPublicURL(path: path)
        return publicURL.absoluteString
    }
    
    func downloadImage(bucket: String, path: String) async throws -> Data {
        try await client.storage.from(bucket).download(path: path)
    }
}
