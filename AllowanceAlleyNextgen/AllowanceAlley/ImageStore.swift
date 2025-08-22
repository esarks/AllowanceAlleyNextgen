import Foundation
import SwiftUI
import PhotosUI

@MainActor
class ImageStore: ObservableObject {
    static let shared = ImageStore()
    
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    
    private let supabaseClient = SupabaseClient.shared
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    func processImage(_ uiImage: UIImage) -> Data? {
        let resizedImage = resizeImage(uiImage, targetSize: AppConfig.thumbnailSize)
        return resizedImage.jpegData(compressionQuality: AppConfig.imageCompressionQuality)
    }
    
    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let ratio = min(widthRatio, heightRatio)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
    
    func uploadImage(_ image: UIImage, fileName: String? = nil) async throws -> String {
        guard let imageData = processImage(image) else {
            throw ImageError.processingFailed
        }
        
        let fileSizeMB = Double(imageData.count) / (1024 * 1024)
        guard fileSizeMB <= Double(AppConfig.maxImageSizeMB) else {
            throw ImageError.fileTooLarge
        }
        
        isUploading = true
        uploadProgress = 0.0
        
        defer {
            Task {
                isUploading = false
                uploadProgress = 0.0
            }
        }
        
        let fileName = fileName ?? "\(UUID().uuidString).jpg"
        let path = "chore_photos/\(fileName)"
        
        uploadProgress = 0.5
        
        let url = try await supabaseClient.uploadImage(imageData, bucket: "photos", path: path)
        
        uploadProgress = 1.0
        
        cache.setObject(image, forKey: NSString(string: url))
        
        return url
    }
    
    func downloadImage(from url: String) async throws -> UIImage {
        if let cachedImage = cache.object(forKey: NSString(string: url)) {
            return cachedImage
        }
        
        guard let urlComponents = URLComponents(string: url),
              let pathComponents = urlComponents.path.components(separatedBy: "/").last else {
            throw ImageError.invalidURL
        }
        
        let data = try await supabaseClient.downloadImage(bucket: "photos", path: "chore_photos/\(pathComponents)")
        
        guard let image = UIImage(data: data) else {
            throw ImageError.invalidImageData
        }
        
        cache.setObject(image, forKey: NSString(string: url))
        
        return image
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
    
    func getCachedImage(for url: String) -> UIImage? {
        cache.object(forKey: NSString(string: url))
    }
}

enum ImageError: LocalizedError {
    case processingFailed
    case fileTooLarge
    case invalidURL
    case invalidImageData
    case uploadFailed
    case downloadFailed
    
    var errorDescription: String? {
        switch self {
        case .processingFailed:
            return "Failed to process image"
        case .fileTooLarge:
            return "Image file is too large"
        case .invalidURL:
            return "Invalid image URL"
        case .invalidImageData:
            return "Invalid image data"
        case .uploadFailed:
            return "Failed to upload image"
        case .downloadFailed:
            return "Failed to download image"
        }
    }
}

// Image Picker Component
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// Async Image View Component
struct AsyncImageView: View {
    let url: String
    let placeholder: Image
    
    @StateObject private var imageStore = ImageStore.shared
    @State private var image: UIImage?
    @State private var isLoading = false
    
    init(url: String, placeholder: Image = Image(systemName: "photo")) {
        self.url = url
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                placeholder
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        if let cachedImage = imageStore.getCachedImage(for: url) {
            image = cachedImage
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let downloadedImage = try await imageStore.downloadImage(from: url)
                await MainActor.run {
                    self.image = downloadedImage
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
                print("Failed to load image: \(error)")
            }
        }
    }
}
