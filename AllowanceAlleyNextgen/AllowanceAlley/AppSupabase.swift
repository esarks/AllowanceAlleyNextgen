// AppSupabase.swift — collision-proof version
import Foundation
import Supabase

// Use a unique name so it can't collide with any previous 'AppConfig'.
enum AppEnv {
    static let url: URL = {
        if let env = ProcessInfo.processInfo.environment["SUPABASE_URL"],
           let u = URL(string: env) { return u }
        if let s = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
           let u = URL(string: s) { return u }
        preconditionFailure("Missing SUPABASE_URL. Provide ENV or Info.plist.")
    }()

    static let anonKey: String = {
        if let k = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] { return k }
        if let k = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String { return k }
        preconditionFailure("Missing SUPABASE_ANON_KEY. Provide ENV or Info.plist.")
    }()
}

final class AppSupabase {
    static let shared = AppSupabase()
    let client: SupabaseClient

    private init() {
        client = SupabaseClient(supabaseURL: AppEnv.url, supabaseKey: AppEnv.anonKey)
    }
}
