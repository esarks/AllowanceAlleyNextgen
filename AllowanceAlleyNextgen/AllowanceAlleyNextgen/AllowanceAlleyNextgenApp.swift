//
//  AllowanceAlleyNextgenApp.swift
//  AllowanceAlleyNextgen
//
//  Created by Paul Marshall on 8/21/25.
//

import SwiftUI
import SwiftData

@main
struct AllowanceAlleyNextgenApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
