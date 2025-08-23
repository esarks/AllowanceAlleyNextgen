import Foundation
import Supabase

struct StorageAPI {
    static let shared = StorageAPI()
    private let client = AppSupabase.shared.client
    private init() {}

    func publicURL(bucket: String, path: String) -> URL? {
        // Some SDK versions mark this as `throws`; keep it safe.
        return try? client.storage.from(bucket).getPublicURL(path: path)
    }
}
