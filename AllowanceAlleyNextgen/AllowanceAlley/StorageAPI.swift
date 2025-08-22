//
//  StorageAPI.swift
//  AllowanceAlleyNextgen
//
//  Created by Paul Marshall on 8/22/25.
//

import Foundation
import Supabase

/// Convenience wrapper for Supabase storage buckets
enum StorageAPI {
    /// Returns a reference to a storage bucket
    static func bucket(_ name: String) -> StorageBucketApi {
        return AppSupabase.shared.client.storage.from(name)
    }
}
