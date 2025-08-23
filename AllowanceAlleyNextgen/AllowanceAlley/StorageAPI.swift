
import Foundation
import Supabase

struct StorageAPI {
    static let shared = StorageAPI()
    private let client = AppSupabase.shared.client

    private init() {}

    func publicURL(bucket: String, path: String) -> URL? {
        return (try? client.storage.from(bucket).getPublicURL(path: path)) ?? nil
    }

    func signedURL(bucket: String, path: String, expiresIn seconds: Int = 3600) async -> URL? {
        do {
            let url = try await client.storage.from(bucket).createSignedURL(path: path, expiresIn: seconds)
            return url
        } catch {
            print("signedURL error:", error)
            return nil
        }
    }
}
