
import Foundation
import Supabase

enum AppEnv {
    static var supabaseURL: URL {
        if let s = ProcessInfo.processInfo.environment["SUPABASE_URL"], let u = URL(string: s) {
            return u
        }
        if let s = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String, let u = URL(string: s) {
            return u
        }
        return URL(string: "https://YOUR-PROJECT.supabase.co")!
    }

    static var supabaseAnonKey: String {
        if let k = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] { return k }
        if let k = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String { return k }
        return "YOUR-ANON-KEY"
    }
}

final class AppSupabase {
    static let shared = AppSupabase()
    let client: SupabaseClient

    private init() {
        client = SupabaseClient(supabaseURL: AppEnv.supabaseURL, supabaseKey: AppEnv.supabaseAnonKey)
    }
}
