//
//  ParentDashboardView.swift
//  AllowanceAlleyNextgen
//
//  Created by Paul Marshall on 8/22/25.
//

import SwiftUI

struct ParentDashboardView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var familyService: FamilyService
    @EnvironmentObject var choreService: ChoreService
    @EnvironmentObject var rewardsService: RewardsService

    @State private var summary = DashboardSummary()
    @State private var isLoading = false
    @State private var showingAddChild = false
    @State private var showingAddChore = false
    @State private var showingAddReward = false

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if isLoading {
                        ProgressView("Loading dashboard...")
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        // Welcome Header
                        welcomeHeader
                        
                        // Quick Stats Cards
                        quickStatsSection
                        
                        // Pending Approvals Alert
                        if summary.pendingApprovals > 0 {
                            pendingApprovalsCard
                        }
                        
                        // Children Summary
                        if !familyService.children.isEmpty {
                            childrenSection
                        }
                        
                        // Quick Actions
                        quickActionsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .refreshable {
                await loadDashboardData()
            }
            .task {
                await loadDashboardData()
            }
            .sheet(isPresented: $showingAddChild) {
                AddChildView()
            }
            .sheet(isPresented: $showingAddChore) {
                AddChoreView()
            }
            .sheet(isPresented: $showingAddReward) {
                AddRewardView()
            }
        }
    }
    
    private var welcomeHeader: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back!")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if let familyName = familyService.currentFamily?.name {
                        Text("\(familyName) Family")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Circle()
                    .fill(Color.blue.gradient)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                    )
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(16)
        }
    }
    
    private var quickStatsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Today's Progress")
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 16) {
                StatCard(
                    title: "Today",
                    completed: summary.todayCompleted,
                    total: summary.todayAssigned,
                    color: .blue
                )
                
                StatCard(
                    title: "This Week",
                    completed: summary.thisWeekCompleted,
                    total: summary.thisWeekAssigned,
                    color: .green
                )
            }
        }
    }
    
    private var pendingApprovalsCard: some View {
        NavigationLink(destination: ApprovalsView()) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.orange)
                        Text("Pending Approvals")
                            .font(.headline)
                    }
                    
                    Text("Tap to review and approve completed chores")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack {
                    Text("\(summary.pendingApprovals)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var childrenSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Children")
                    .font(.headline)
                Spacer()
                Text("\(familyService.children.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
            }
            
            ForEach(familyService.children) { child in
                ChildSummaryCard(child: child)
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionButton(
                    icon: "list.bullet.clipboard",
                    title: "Add Chore",
                    color: .blue
                ) {
                    showingAddChore = true
                }
                
                QuickActionButton(
                    icon: "gift.fill",
                    title: "Add Reward",
                    color: .purple
                ) {
                    showingAddReward = true
                }
                
                QuickActionButton(
                    icon: "person.badge.plus",
                    title: "Add Child",
                    color: .green
                ) {
                    showingAddChild = true
                }
                
                QuickActionButton(
                    icon: "chart.bar.fill",
                    title: "View Reports",
                    color: .orange
                ) {
                    // TODO: Navigate to reports
                }
            }
        }
    }

    private func loadDashboardData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await familyService.loadFamily()
            try await choreService.loadChores()
            try await choreService.loadAssignments()
            try await choreService.loadCompletions()
            try await rewardsService.loadRewards()
            try await rewardsService.loadRedemptions()
            summary = await choreService.getDashboardSummary()
        } catch {
            print("Failed to load dashboard data: \(error)")
        }
    }
}
