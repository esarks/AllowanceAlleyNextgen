import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var choreService: ChoreService
    @EnvironmentObject var rewardsService: RewardsService

    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        NavigationView {
            List {
                if let error {
                    Text(error).foregroundColor(.red)
                }

                Section("Family") {
                    Text("Family ID")
                    Spacer()
                    Text(authService.currentUser?.familyId ?? "None")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Actions") {
                    Button {
                        Task { await refresh() }
                    } label: {
                        if isLoading {
                            ProgressView().progressViewStyle(.circular)
                        } else {
                            Text("Refresh Data")
                        }
                    }
                }
            }
            .navigationTitle("Dashboard")
            .task { await refresh() }
        }
    }

    private func refresh() async {
        isLoading = true
        defer { isLoading = false }

        guard let familyId = authService.currentUser?.familyId else {
            self.error = "No family selected"
            return
        }

        // These service APIs expect a familyId
        await choreService.loadAll(for: familyId)
        await rewardsService.loadAll(familyId: familyId)
    }
}
