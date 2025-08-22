import Foundation
import CoreGraphics

enum VerificationMode {
    case inlineCode   // show 6-digit code on screen (dev)
    case emailLink    // real email verification (prod)
}

struct AppConfig {
    static let supabaseURL: String = {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              !url.isEmpty else { fatalError("SUPABASE_URL not found in Info.plist") }
        return url
    }()

    static let supabaseAnonKey: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              !key.isEmpty else { fatalError("SUPABASE_ANON_KEY not found in Info.plist") }
        return key
    }()

    // 👇 flip to .emailLink in prod
    static let verificationMode: VerificationMode = .inlineCode

    static let appName = "Allowance Alley"
    static let minimumIOSVersion = "15.0"

    static let defaultDueSoonMinutes = 60
    static let maxNotificationDays = 7

    static let maxImageSizeMB = 5
    static let imageCompressionQuality: CGFloat = 0.8
    static let thumbnailSize = CGSize(width: 200, height: 200)

    static let syncBatchSize = 50
    static let maxRetryAttempts = 3
    static let syncIntervalSeconds: TimeInterval = 30
}
