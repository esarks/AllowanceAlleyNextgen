import Foundation
#if canImport(UIKit)
import UIKit
#endif

// Stubs so ImageStore compiles even if your real Supabase storage wiring
// isn't ready yet. Safe to keep for local builds; replace with real calls later.
extension SupabaseClient {
    // Data-based upload
    @discardableResult
    func uploadImage(_ data: Data, bucket: String, path: String) async throws -> String {
        // Pretend we uploaded and return a deterministic fake public URL.
        return "https://example.com/\(bucket)/\(path)"
    }

    // UIImage convenience (if ImageStore calls this overload)
    #if canImport(UIKit)
    @discardableResult
    func uploadImage(_ image: UIImage, bucket: String, path: String, compressionQuality: CGFloat = 0.85) async throws -> String {
        guard let data = image.jpegData(compressionQuality: compressionQuality) ?? image.pngData() else {
            throw NSError(domain: "UploadImageStub", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not encode image"])
        }
        return try await uploadImage(data, bucket: bucket, path: path)
    }
    #endif

    // Download
    func downloadImage(bucket: String, path: String) async throws -> Data {
        // Return empty data for now; swap with real download later.
        return Data()
    }
}
