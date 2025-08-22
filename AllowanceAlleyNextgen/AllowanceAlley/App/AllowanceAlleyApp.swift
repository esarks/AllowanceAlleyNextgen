//
//  AllowanceAlleyApp.swift
//  AllowanceAlley
//

import SwiftUI
import Combine

@main
struct AllowanceAlleyApp: App {
    @StateObject private var coreDataStack = CoreDataStack.shared
    @StateObject private var supabaseClient = SupabaseClient.shared
    @StateObject private var authService = AuthService.shared
    @StateObject private var familyService = FamilyService.shared
    @StateObject private var choreService = ChoreService.shared
    @StateObject private var rewardsService = RewardsService.shared
    @StateObject private var notificationsService = NotificationsService.shared
    @StateObject private var imageStore = ImageStore.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coreDataStack)
                .environmentObject(supabaseClient)
                .environmentObject(authService)
                .environmentObject(familyService)
                .environmentObject(choreService)
                .environmentObject(rewardsService)
                .environmentObject(notificationsService)
                .environmentObject(imageStore)
                .onAppear {
                    setupServices()
                }
        }
    }
    
    private func setupServices() {
        authService.initialize()
        notificationsService.requestPermissions()
    }
}

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showingLogin = true
    @State private var showingPINEntry = false
    @State private var selectedChildId: String?
    
    var body: some View {
        NavigationView {
            if authService.isAuthenticated {
                if authService.currentUser?.role == .parent {
                    DashboardView()
                } else if let childId = selectedChildId {
                    TodayView(childId: childId)
                } else {
                    ChildSelectionView(selectedChildId: $selectedChildId)
                }
            } else {
                AuthenticationView(
                    showingLogin: $showingLogin,
                    showingPINEntry: $showingPINEntry,
                    selectedChildId: $selectedChildId
                )
            }
        }
        .accentColor(.blue)
    }
}

struct AuthenticationView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var familyService: FamilyService
    @Binding var showingLogin: Bool
    @Binding var showingPINEntry: Bool
    @Binding var selectedChildId: String?
    
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var familyName = ""
    @State private var pin = ""
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 24) {
            // App Header
            VStack(spacing: 8) {
                Image(systemName: "house.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Allowance Alley")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Chores & Rewards for Families")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            
            if showingPINEntry {
                PINEntryView(
                    pin: $pin,
                    selectedChildId: $selectedChildId,
                    showingPINEntry: $showingPINEntry
                )
            } else {
                ParentLoginView(
                    email: $email,
                    password: $password,
                    familyName: $familyName,
                    isSignUp: $isSignUp,
                    errorMessage: $errorMessage
                )
            }
            
            // Switch between Parent/Child
            HStack(spacing: 20) {
                Button(showingPINEntry ? "Parent Login" : "Child Login") {
                    showingPINEntry.toggle()
                    errorMessage = ""
                }
                .foregroundColor(.blue)
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

struct ParentLoginView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var familyService: FamilyService
    @Binding var email: String
    @Binding var password: String
    @Binding var familyName: String
    @Binding var isSignUp: Bool
    @Binding var errorMessage: String
    
    var body: some View {
        VStack(spacing: 16) {
            Text(isSignUp ? "Create Parent Account" : "Parent Login")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.password)
                
                if isSignUp {
                    TextField("Family Name", text: $familyName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.organizationName)
                }
            }
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: authenticate) {
                Text(isSignUp ? "Create Account" : "Sign In")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .disabled(email.isEmpty || password.isEmpty || (isSignUp && familyName.isEmpty))
            
            Button(isSignUp ? "Already have an account? Sign In" : "Need an account? Sign Up") {
                isSignUp.toggle()
                errorMessage = ""
            }
            .foregroundColor(.blue)
        }
    }
    
    private func authenticate() {
        Task {
            do {
                if isSignUp {
                    try await authService.signUp(email: email, password: password)
                    try await familyService.createFamily(name: familyName)
                } else {
                    try await authService.signIn(email: email, password: password)
                }
                errorMessage = ""
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct PINEntryView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var familyService: FamilyService
    @Binding var pin: String
    @Binding var selectedChildId: String?
    @Binding var showingPINEntry: Bool
    
    @State private var children: [AppUser] = []
    @State private var selectedChild: AppUser?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Child Login")
                .font(.title2)
                .fontWeight(.semibold)
            
            if children.isEmpty {
                Text("No children found. Ask a parent to add you!")
                    .foregroundColor(.secondary)
            } else {
                // Child Selection
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(children) { child in
                            VStack {
                                Circle()
                                    .fill(selectedChild?.id == child.id ? Color.blue : Color.gray.opacity(0.3))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Text(String(child.displayName.prefix(2)).uppercased())
                                            .font(.headline)
                                            .foregroundColor(selectedChild?.id == child.id ? .white : .primary)
                                    )
                                
                                Text(child.displayName)
                                    .font(.caption)
                            }
                            .onTapGesture {
                                selectedChild = child
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // PIN Entry
                if selectedChild != nil {
                    VStack(spacing: 12) {
                        Text("Enter PIN for \(selectedChild?.displayName ?? "")")
                            .font(.headline)
                        
                        SecureField("PIN", text: $pin)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .font(.title)
                        
                        Button("Sign In") {
                            authenticateChild()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(12)
                        .disabled(pin.isEmpty)
                    }
                }
            }
        }
        .onAppear {
            loadChildren()
        }
    }
    
    private func loadChildren() {
        Task {
            children = await familyService.getChildren()
        }
    }
    
    private func authenticateChild() {
        guard let child = selectedChild else { return }
        
        Task {
            do {
                try await authService.signInChild(childId: child.id, pin: pin)
                selectedChildId = child.id
            } catch {
                // Handle error
            }
        }
    }
}

struct ChildSelectionView: View {
    @EnvironmentObject var familyService: FamilyService
    @Binding var selectedChildId: String?
    
    @State private var children: [AppUser] = []
    
    var body: some View {
        VStack {
            Text("Select Child")
                .font(.title)
                .padding()
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2)) {
                ForEach(children) { child in
                    VStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(String(child.displayName.prefix(2)).uppercased())
                                    .font(.title)
                                    .foregroundColor(.white)
                            )
                        
                        Text(child.displayName)
                            .font(.headline)
                    }
                    .padding()
                    .onTapGesture {
                        selectedChildId = child.id
                    }
                }
            }
            .padding()
            
            Spacer()
        }
        .onAppear {
            loadChildren()
        }
    }
    
    private func loadChildren() {
        Task {
            children = await familyService.getChildren()
        }
    }
}