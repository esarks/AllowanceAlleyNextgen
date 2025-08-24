import Foundation
import SwiftUI

@MainActor
class ImageStore: ObservableObject {
    static let shared = ImageStore()

    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024
    }

    func processImage(_ uiImage: UIImage) -> Data? {
        let resizedImage = resizeImage(uiImage, targetSize: AppConfig.thumbnailSize)
        return resizedImage.jpegData(compressionQuality: AppConfig.imageCompressionQuality)
    }

    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let ratio = min(targetSize.width / size.width, targetSize.height / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? image
    }

    func uploadImage(_ image: UIImage, fileName: String? = nil) async throws -> String {
        guard let imageData = processImage(image) else { throw ImageError.processingFailed }
        let fileSizeMB = Double(imageData.count) / (1024 * 1024)
        guard fileSizeMB <= Double(AppConfig.maxImageSizeMB) else { throw ImageError.fileTooLarge }

        isUploading = true
        uploadProgress = 0.0
        defer { Task { @MainActor in self.isUploading = false; self.uploadProgress = 0.0 } }

        let name = fileName ?? "\(UUID().uuidString).jpg"
        let path = "chore_photos/\(name)"

        uploadProgress = 0.5
        let url = try await StorageAPI.shared.uploadImage(imageData, bucket: "photos", path: path)
        uploadProgress = 1.0

        cache.setObject(image, forKey: NSString(string: url))
        return url
    }

    func downloadImage(from url: String) async throws -> UIImage {
        if let cached = cache.object(forKey: NSString(string: url)) { return cached }
        guard let comps = URLComponents(string: url),
              let last = comps.path.split(separator: "/").last else { throw ImageError.invalidURL }
        let data = try await StorageAPI.shared.downloadImage(bucket: "photos", path: "chore_photos/\(last)")
        guard let image = UIImage(data: data) else { throw ImageError.invalidImageData }
        cache.setObject(image, forKey: NSString(string: url))
        return image
    }

    func clearCache() { cache.removeAllObjects() }
    func getCachedImage(for url: String) -> UIImage? { cache.object(forKey: NSString(string: url)) }
}

enum ImageError: LocalizedError {
    case processingFailed, fileTooLarge, invalidURL, invalidImageData, uploadFailed, downloadFailed
    var errorDescription: String? {
        switch self {
        case .processingFailed: return "Failed to process image"
        case .fileTooLarge: return "Image file is too large"
        case .invalidURL: return "Invalid image URL"
        case .invalidImageData: return "Invalid image data"
        case .uploadFailed: return "Failed to upload image"
        case .downloadFailed: return "Failed to download image"
        }
    }
}
