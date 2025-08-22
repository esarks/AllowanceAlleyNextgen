import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var familyService: FamilyService
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                if let user = authService.currentUser {
                    switch user.role {
                    case .parent:
                        DashboardView()
                    case .child:
                        TodayView(childId: user.id)
                    }
                } else {
                    Text("Loading user data...")
                        .onAppear {
                            Task {
                                try await authService.signOut()
                            }
                        }
                }
            } else if authService.pendingVerificationEmail != nil {
                EmailVerificationView()
            } else {
                AuthenticationView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authService.isAuthenticated)
    }
}

struct AuthenticationView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var familyService: FamilyService
    
    @State private var isShowingSignUp = false
    @State private var isShowingSignIn = false
    @State private var isShowingChildLogin = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // App Logo/Title
                VStack(spacing: 16) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Allowance Alley")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Manage chores and rewards for your family")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Authentication Options
                VStack(spacing: 16) {
                    Button(action: { isShowingSignUp = true }) {
                        HStack {
                            Image(systemName: "person.2.fill")
                            Text("Create Family Account")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .accessibilityLabel("Create Family Account")
                    
                    Button(action: { isShowingSignIn = true }) {
                        HStack {
                            Image(systemName: "person.fill")
                            Text("Parent Sign In")
                        }
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                    }
                    .accessibilityLabel("Parent Sign In")
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                        
                        Text("or")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                    }
                    
                    Button(action: { isShowingChildLogin = true }) {
                        HStack {
                            Image(systemName: "person.crop.circle.fill")
                            Text("I'm a Kid")
                        }
                        .font(.headline)
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green, lineWidth: 2)
                        )
                    }
                    .accessibilityLabel("Child Sign In")
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                Text("Demo Version - All data is simulated")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $isShowingSignUp) {
            ParentSignUpView()
        }
        .sheet(isPresented: $isShowingSignIn) {
            ParentSignInView()
        }
        .sheet(isPresented: $isShowingChildLogin) {
            ChildLoginView()
        }
    }
}

struct ParentSignUpView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var familyName = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Family Information") {
                    TextField("Family Name", text: $familyName)
                        .textContentType(.organizationName)
                        .accessibilityLabel("Family Name")
                }
                
                Section("Parent Account") {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .accessibilityLabel("Email Address")
                    
                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                        .accessibilityLabel("Password")
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                        .accessibilityLabel("Confirm Password")
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .accessibilityLabel("Error: \(errorMessage)")
                    }
                }
                
                Section {
                    Button(action: signUp) {
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Create Account")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                    .accessibilityLabel("Create Account")
                }
            }
            .navigationTitle("Create Family")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel")
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && !familyName.isEmpty && 
        password == confirmPassword && password.count >= 6
    }
    
    private func signUp() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                try await authService.signUp(email: email, password: password, familyName: familyName)
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

struct ParentSignInView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Sign In") {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .accessibilityLabel("Email Address")
                    
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .accessibilityLabel("Password")
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .accessibilityLabel("Error: \(errorMessage)")
                    }
                }
                
                Section {
                    Button(action: signIn) {
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Sign In")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                    .accessibilityLabel("Sign In")
                }
            }
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel")
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    private func signIn() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                try await authService.signIn(email: email, password: password)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

struct ChildLoginView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var familyService: FamilyService
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedChild: Child?
    @State private var enteredPIN = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("Choose Your Profile")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Select your name and enter your PIN")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Demo children
                VStack(spacing: 16) {
                    Text("Demo Children")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    ForEach(demoChildren, id: \.id) { child in
                        Button(action: {
                            selectedChild = child
                            enteredPIN = ""
                        }) {
                            HStack {
                                Circle()
                                    .fill(selectedChild?.id == child.id ? Color.green : Color.gray.opacity(0.3))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Text(String(child.name.prefix(2)).uppercased())
                                            .font(.headline)
                                            .foregroundColor(selectedChild?.id == child.id ? .white : .primary)
                                    )
                                
                                Text(child.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if selectedChild?.id == child.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                            .padding()
                            .background(selectedChild?.id == child.id ? Color.green.opacity(0.1) : Color.gray.opacity(0.05))
                            .cornerRadius(12)
                        }
                        .accessibilityLabel("Select \(child.name)")
                    }
                }
                .padding(.horizontal)
                
                if selectedChild != nil {
                    VStack(spacing: 16) {
                        Text("Enter your PIN")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            ForEach(0..<4, id: \.self) { index in
                                Circle()
                                    .fill(index < enteredPIN.count ? Color.green : Color.gray.opacity(0.3))
                                    .frame(width: 20, height: 20)
                            }
                        }
                        .accessibilityLabel("PIN entry. \(enteredPIN.count) of 4 digits entered")
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                            ForEach(1...9, id: \.self) { number in
                                Button(action: {
                                    if enteredPIN.count < 4 {
                                        enteredPIN += String(number)
                                    }
                                }) {
                                    Text(String(number))
                                        .font(.title)
                                        .fontWeight(.semibold)
                                        .frame(width: 60, height: 60)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(30)
                                }
                                .accessibilityLabel("Digit \(number)")
                            }
                            
                            Color.clear.frame(width: 60, height: 60)
                            
                            Button(action: {
                                if enteredPIN.count < 4 {
                                    enteredPIN += "0"
                                }
                            }) {
                                Text("0")
                                    .font(.title)
                                    .fontWeight(.semibold)
                                    .frame(width: 60, height: 60)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(30)
                            }
                            .accessibilityLabel("Digit 0")
                            
                            Button(action: {
                                if !enteredPIN.isEmpty {
                                    enteredPIN.removeLast()
                                }
                            }) {
                                Image(systemName: "delete.left")
                                    .font(.title2)
                                    .frame(width: 60, height: 60)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(30)
                            }
                            .accessibilityLabel("Delete")
                        }
                        .padding(.horizontal)
                        
                        if enteredPIN.count == 4 {
                            Button(action: signInChild) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Sign In")
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.green)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .disabled(isLoading)
                            .accessibilityLabel("Sign In")
                        }
                    }
                }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .accessibilityLabel("Error: \(errorMessage)")
                }
                
                Spacer()
            }
            .navigationTitle("Kid Login")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel")
                }
            }
        }
    }
    
    private var demoChildren: [Child] {
        [
            Child(parentUserId: "demo", name: "Emma", birthdate: Calendar.current.date(byAdding: .year, value: -8, to: Date())),
            Child(parentUserId: "demo", name: "Jake", birthdate: Calendar.current.date(byAdding: .year, value: -10, to: Date())),
            Child(parentUserId: "demo", name: "Sophie", birthdate: Calendar.current.date(byAdding: .year, value: -6, to: Date()))
        ]
    }
    
    private func signInChild() {
        guard let child = selectedChild else { return }
        
        // Demo PINs: Emma=1234, Jake=5678, Sophie=9999
        let demoPins = ["Emma": "1234", "Jake": "5678", "Sophie": "9999"]
        let expectedPin = demoPins[child.name] ?? "0000"
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                if enteredPIN == expectedPin {
                    try await authService.signInChild(childId: child.id, pin: enteredPIN)
                    await MainActor.run {
                        dismiss()
                    }
                } else {
                    await MainActor.run {
                        errorMessage = "Incorrect PIN. Try again."
                        enteredPIN = ""
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Sign in failed. Try again."
                    enteredPIN = ""
                    isLoading = false
                }
            }
        }
    }
}

struct EmailVerificationView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    
    @State private var isCheckingVerification = false
    @State private var isResendingEmail = false
    @State private var showingSuccess = false
    @State private var errorMessage = ""
    @State private var resendCooldown = 0
    @State private var timer: Timer?
    
    var email: String {
        authService.pendingVerificationEmail ?? ""
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "envelope.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                VStack(spacing: 12) {
                    Text("Check Your Email")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("We sent a verification link to:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(email)
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "1.circle.fill")
                                .foregroundColor(.blue)
                            Text("Open your email app")
                        }
                        
                        HStack {
                            Image(systemName: "2.circle.fill")
                                .foregroundColor(.blue)
                            Text("Click the verification link")
                        }
                        
                        HStack {
                            Image(systemName: "3.circle.fill")
                                .foregroundColor(.blue)
                            Text("Come back and tap 'I've Verified'")
                        }
                    }
                    .font(.subheadline)
                    
                    Text("The link will expire in 24 hours")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button(action: checkVerification) {
                        HStack {
                            if isCheckingVerification {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.circle")
                            }
                            Text("I've Verified My Email")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(isCheckingVerification)
                    .accessibilityLabel("I've Verified My Email")
                    
                    Button(action: resendVerificationEmail) {
                        HStack {
                            if isResendingEmail {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            
                            if resendCooldown > 0 {
                                Text("Resend in \(resendCooldown)s")
                            } else {
                                Text("Resend Email")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                    }
                    .disabled(isResendingEmail || resendCooldown > 0)
                    .accessibilityLabel(resendCooldown > 0 ? "Resend in \(resendCooldown) seconds" : "Resend Email")
                    
                    Button("Use Different Email") {
                        Task {
                            try await authService.signOut()
                            dismiss()
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Use Different Email")
                }
                .padding(.horizontal)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                        .accessibilityLabel("Error: \(errorMessage)")
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
        .alert("Email Verified!", isPresented: $showingSuccess) {
            Button("Continue") {
                dismiss()
            }
        } message: {
            Text("Your email has been verified successfully. Welcome to Allowance Alley!")
        }
        .onAppear {
            startResendCooldown()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func checkVerification() {
        isCheckingVerification = true
        errorMessage = ""
        
        Task {
            // Simulate verification check
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            await MainActor.run {
                isCheckingVerification = false
                showingSuccess = true
            }
        }
    }
    
    private func resendVerificationEmail() {
        isResendingEmail = true
        errorMessage = ""
        
        Task {
            // Simulate resend
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            await MainActor.run {
                isResendingEmail = false
                startResendCooldown()
            }
        }
    }
    
    private func startResendCooldown() {
        resendCooldown = 60
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if resendCooldown > 0 {
                resendCooldown -= 1
            } else {
                timer?.invalidate()
                timer = nil
            }
        }
    }
}
