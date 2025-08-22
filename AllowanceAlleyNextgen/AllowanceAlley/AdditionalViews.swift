//
//  AdditionalViews.swift
//  AllowanceAlleyNextgen
//
//  Created by Paul Marshall on 8/22/25.
//

import SwiftUI

struct ReportsView: View {
    @EnvironmentObject var choreService: ChoreService
    @EnvironmentObject var familyService: FamilyService
    @EnvironmentObject var rewardsService: RewardsService
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Family Reports")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Coming Soon")
                            .font(.headline)
                        
                        Text("• Weekly progress reports")
                        Text("• Points earned history")
                        Text("• Chore completion trends")
                        Text("• Family achievements")
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Reports")
        }
    }
}

struct ParentSettingsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var notificationsService: NotificationsService
    
    var body: some View {
        NavigationView {
            List {
                Section("Account") {
                    if let user = authService.currentUser {
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(user.email ?? "Not set")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Family Name")
                            Spacer()
                            Text(user.displayName)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Notifications") {
                    Toggle("Allow Notifications", isOn: $notificationsService.isAuthorized)
                        .disabled(true) // Read-only for now
                    
                    Button("Request Notification Permission") {
                        notificationsService.requestPermissions()
                    }
                }
                
                Section("Data") {
                    Button("Export Family Data") {
                        // TODO: Implement data export
                    }
                    
                    Button("Import Data") {
                        // TODO: Implement data import
                    }
                }
                
                Section {
                    Button("Sign Out") {
                        Task {
                            try? await authService.signOut()
                        }
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct ChildSettingsView: View {
    let childId: String
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationView {
            List {
                Section("About Me") {
                    HStack {
                        Text("Child ID")
                        Spacer()
                        Text(childId)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Privacy") {
                    Text("Your data is safe with us")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    Button("Sign Out") {
                        Task {
                            try? await authService.signOut()
                        }
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct RewardsView: View {
    let childId: String
    
    var body: some View {
        // Redirect to the proper child rewards view
        ChildRewardsView(childId: childId)
    }
}
