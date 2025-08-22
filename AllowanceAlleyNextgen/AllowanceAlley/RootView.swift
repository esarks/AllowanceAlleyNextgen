import SwiftUI

struct RootView: View {
    @EnvironmentObject var authService: AuthService
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                SplashView()
                    .task {
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        isLoading = false
                    }
            } else {
                ContentView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
        .animation(.easeInOut(duration: 0.3), value: authService.isAuthenticated)
    }
}

struct SplashView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "house.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            Text("Allowance Alley")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            ProgressView()
                .scaleEffect(1.2)
                .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
}