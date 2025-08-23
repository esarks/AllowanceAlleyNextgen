import Foundation
import Supabase

final class StorageAPI {
    static let shared = StorageAPI()
    private let client = AppSupabase.shared.client
    private init() {}

    @discardableResult
    func uploadImage(_ data: Data, bucket: String, path: String) async throws -> String {
        // NEW API: upload(_:data:options:)
        try await client.storage
            .from(bucket)
            .upload(path, data: data)

        let publicURL = try client.storage
            .from(bucket)
            .getPublicURL(path: path)

        return publicURL.absoluteString
    }

    func downloadImage(bucket: String, path: String) async throws -> Data {
        try await client.storage
            .from(bucket)
            .download(path: path)
    }
}
