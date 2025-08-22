import SwiftUI

struct ParentMainView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ParentDashboardView()
                .tabItem { Label("Dashboard", systemImage: "house.fill") }
                .tag(0)
            ParentChoresView()
                .tabItem { Label("Chores", systemImage: "checklist") }
                .tag(1)
            ApprovalsView()
                .tabItem { Label("Approvals", systemImage: "checkmark.seal.fill") }
                .tag(2)
            ReportsView()
                .tabItem { Label("Reports", systemImage: "doc.plaintext") }
                .tag(3)
            ParentSettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(4)
        }
    }
}