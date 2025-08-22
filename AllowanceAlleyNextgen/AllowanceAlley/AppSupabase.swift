import Foundation
import Supabase

final class AppSupabase {
    static let shared = AppSupabase()
    let client: SupabaseClient
    
    private init() {
        guard let url = URL(string: AppConfig.supabaseURL) else {
            fatalError("Invalid SUPABASE_URL")
        }
        
        // Updated Supabase client initialization
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: AppConfig.supabaseAnonKey
        )
    }
}
