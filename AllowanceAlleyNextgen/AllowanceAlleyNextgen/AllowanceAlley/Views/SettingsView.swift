//
//  SettingsView.swift
//  AllowanceAlley
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var familyService: FamilyService
    @EnvironmentObject var notificationsService: NotificationsService
    @EnvironmentObject var imageStore: ImageStore
    @Environment(\.dismiss) var dismiss
    
    @State private var showingSignOutConfirmation = false
    @State private var showingDeleteFamilyConfirmation = false
    @State private var showLeaderboard = true
    @State private var allowNotifications = true
    @State private var dueSoonMinutes = 60
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                // User Info Section
                Section("Account") {
                    if let user = authService.currentUser {
                        HStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Text(String(user.displayName.prefix(2)).uppercased())
                                        .font(.headline)
                                        .foregroundColor(.white)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.displayName)
                                    .font(.headline)
                                
                                Text(user.email ?? "No email")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(user.role.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(user.role == .parent ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                                    .cornerRadius(4)
                            }
                            
                            Spacer()
                        }
                    }
                }
                
                // Family Info Section
                if let family = familyService.currentFamily {
                    Section("Family") {
                        HStack {
                            Image(systemName: "house.fill")
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(family.name)
                                    .font(.headline)
                                
                                Text("\(familyService.children.count) children")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                }
                
                // App Settings Section
                Section("App Settings") {
                    Toggle("Show Leaderboard", isOn: $showLeaderboard)
                        .onChange(of: showLeaderboard) { newValue in
                            saveAppSettings()
                        }
                    
                    NavigationLink("Manage Family") {
                        FamilyManagerView()
                    }
                    .disabled(authService.currentUser?.role != .parent)
                }
                
                // Notification Settings Section
                Section("Notifications") {
                    Toggle("Allow Notifications", isOn: $allowNotifications)
                        .onChange(of: allowNotifications) { newValue in
                            if newValue {
                                notificationsService.requestPermissions()
                            }
                            saveNotificationSettings()
                        }
                    
                    if allowNotifications {
                        HStack {
                            Text("Remind me")
                            
                            Spacer()
                            
                            Picker("Minutes before due", selection: $dueSoonMinutes) {
                                Text("15 min").tag(15)
                                Text("30 min").tag(30)
                                Text("1 hour").tag(60)
                                Text("2 hours").tag(120)
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        .onChange(of: dueSoonMinutes) { newValue in
                            saveNotificationSettings()
                        }
                    }
                }
                
                // Storage & Cache Section
                Section("Storage") {
                    Button("Clear Image Cache") {
                        imageStore.clearCache()
                    }
                    .foregroundColor(.blue)
                    
                    HStack {
                        Text("Cache Status")
                        Spacer()
                        Text("Active")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                // About Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("2024.1")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("Privacy Policy", destination: URL(string: "https://allowancealley.app/privacy")!)
                        .foregroundColor(.blue)
                    
                    Link("Terms of Service", destination: URL(string: "https://allowancealley.app/terms")!)
                        .foregroundColor(.blue)
                }
                
                // Danger Zone Section (Parent only)
                if authService.currentUser?.role == .parent {
                    Section("Danger Zone") {
                        Button("Delete Family") {
                            showingDeleteFamilyConfirmation = true
                        }
                        .foregroundColor(.red)
                    }
                }
                
                // Sign Out Section
                Section {
                    Button("Sign Out") {
                        showingSignOutConfirmation = true
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Sign Out", isPresented: $showingSignOutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Family", isPresented: $showingDeleteFamilyConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteFamily()
            }
        } message: {
            Text("This will permanently delete your family and all associated data. This action cannot be undone.")
        }
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        // Load notification settings
        allowNotifications = notificationsService.isAuthorized
        
        if let userId = authService.currentUser?.id,
           let prefs = notificationsService.notificationPrefs[userId] {
            dueSoonMinutes = prefs.dueSoonMinutesBefore
            allowNotifications = prefs.allowReminders
        }
    }
    
    private func saveAppSettings() {
        // Save app settings to UserDefaults or similar
        UserDefaults.standard.set(showLeaderboard, forKey: "showLeaderboard")
    }
    
    private func saveNotificationSettings() {
        guard let userId = authService.currentUser?.id else { return }
        
        Task {
            do {
                let prefs = NotificationPref(
                    userId: userId,
                    dueSoonMinutesBefore: dueSoonMinutes,
                    allowReminders: allowNotifications
                )
                
                if notificationsService.notificationPrefs[userId] != nil {
                    try await notificationsService.updateNotificationPrefs(prefs)
                } else {
                    try await notificationsService.saveNotificationPrefs(prefs)
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save notification settings"
                }
            }
        }
    }
    
    private func signOut() {
        Task {
            do {
                try await authService.signOut()
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func deleteFamily() {
        // Implementation for deleting family
        // This would require additional backend support
        errorMessage = "Family deletion is not yet implemented"
    }
}