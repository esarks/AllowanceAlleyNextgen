//
//  MainsView.swift
//  AllowanceAlleyNextgen
//
//  Created by Paul Marshall on 8/23/25.
//
import SwiftUI

// MARK: - Parent Main

struct ParentMainView: View {
    var body: some View {
        TabView {
            ParentDashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            ReportsView()
                .tabItem { Label("Reports", systemImage: "chart.bar.fill") }

            ParentSettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

// MARK: - Child Main

struct ChildMainView: View {
    let childId: String

    var body: some View {
        TabView {
            ChildChoresView(childId: childId)
                .tabItem { Label("Chores", systemImage: "checklist") }

            ChildRewardsView(childId: childId)
                .tabItem { Label("Rewards", systemImage: "gift.fill") }

            ChildSettingsView(childId: childId)
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

// MARK: - Child Chores (simple placeholder hooked to your services)

struct ChildChoresView: View {
    let childId: String
    @EnvironmentObject var choreService: ChoreService

    @State private var todays: [ChoreAssignment] = []

    var body: some View {
        NavigationView {
            List {
                if todays.isEmpty {
                    Text("No chores due today 🎉").foregroundColor(.secondary)
                } else {
                    ForEach(todays, id: \.id) { a in
                        VStack(alignment: .leading) {
                            Text(choreTitle(for: a.choreId))
                                .font(.headline)
                            if let due = a.dueDate {
                                Text("Due: \(due.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Chores")
            .task {
                // use what you already load into the service
                todays = choreService.getTodayAssignments(for: childId)
            }
        }
    }

    private func choreTitle(for choreId: String) -> String {
        choreService.chores.first(where: { $0.id == choreId })?.title ?? "Chore"
    }
}

