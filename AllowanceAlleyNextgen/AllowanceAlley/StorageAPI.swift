import Foundation
import Supabase

struct StorageAPI {
    static let shared = StorageAPI()
    private let client = AppSupabase.shared.client
    private init() {}

    /// Build a public URL for a stored object (nil if it can’t be built).
    func publicURL(bucket: String, path: String) -> URL? {
        // Some SDK versions mark this as `throws`; keep it safe.
        return try? client.storage.from(bucket).getPublicURL(path: path)
    }

    /// Upload raw image bytes and return the **public URL string**.
    func uploadImage(_ data: Data, bucket: String, path: String) async throws -> String {
        // IMPORTANT: Your SDK’s initializer order is cacheControl → contentType → upsert
        let options = FileOptions(cacheControl: "3600", contentType: "image/jpeg", upsert: true)

        _ = try await client.storage
            .from(bucket)
            .upload(path: path, file: data, options: options)

        guard let url = publicURL(bucket: bucket, path: path) else {
            throw NSError(
                domain: "Storage",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create public URL"]
            )
        }
        return url.absoluteString
    }

    /// Download file data for a bucket/path.
    func downloadImage(bucket: String, path: String) async throws -> Data {
        try await client.storage.from(bucket).download(path: path)
    }
}
