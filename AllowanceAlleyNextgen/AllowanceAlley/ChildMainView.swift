import SwiftUI

struct ChildMainView: View {
    let childId: String
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ChildDashboardView(childId: childId)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)
            ChildChoresView(childId: childId)
                .tabItem { Label("My Chores", systemImage: "list.bullet") }
                .tag(1)
            RewardsView(childId: childId)
                .tabItem { Label("Rewards", systemImage: "star.fill") }
                .tag(2)
            ChildSettingsView(childId: childId)
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(3)
        }
    }
}