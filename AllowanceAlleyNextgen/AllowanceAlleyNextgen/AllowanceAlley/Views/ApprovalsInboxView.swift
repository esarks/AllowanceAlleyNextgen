//
//  ApprovalsInboxView.swift
//  AllowanceAlley
//

import SwiftUI

struct ApprovalsInboxView: View {
    @EnvironmentObject var choreService: ChoreService
    @EnvironmentObject var rewardsService: RewardsService
    @EnvironmentObject var familyService: FamilyService
    
    @State private var selectedTab = 0
    @State private var chores: [String: Chore] = [:]
    @State private var rewards: [String: Reward] = [:]
    @State private var children: [String: AppUser] = [:]
    
    var pendingChoreApprovals: [ChoreInstance] {
        choreService.pendingApprovals
    }
    
    var pendingRedemptions: [Redemption] {
        rewardsService.getPendingRedemptions()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Picker
            Picker("Approval Type", selection: $selectedTab) {
                Text("Chores (\(pendingChoreApprovals.count))").tag(0)
                Text("Rewards (\(pendingRedemptions.count))").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Content
            TabView(selection: $selectedTab) {
                // Chore Approvals
                ChoreApprovalsView(
                    instances: pendingChoreApprovals,
                    chores: chores,
                    children: children
                )
                .tag(0)
                
                // Reward Redemptions
                RewardApprovalsView(
                    redemptions: pendingRedemptions,
                    rewards: rewards,
                    children: children
                )
                .tag(1)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .navigationTitle("Approvals")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadData()
        }
        .refreshable {
            loadData()
        }
    }
    
    private func loadData() {
        Task {
            await choreService.loadChoreInstances()
            try await choreService.loadChores()
            try await rewardsService.loadRedemptions()
            try await rewardsService.loadRewards()
            
            // Create lookup dictionaries
            chores = Dictionary(uniqueKeysWithValues: choreService.chores.map { ($0.id, $0) })
            rewards = Dictionary(uniqueKeysWithValues: rewardsService.rewards.map { ($0.id, $0) })
            children = Dictionary(uniqueKeysWithValues: familyService.children.map { ($0.id, $0) })
        }
    }
}

struct ChoreApprovalsView: View {
    let instances: [ChoreInstance]
    let chores: [String: Chore]
    let children: [String: AppUser]
    
    @EnvironmentObject var choreService: ChoreService
    
    var body: some View {
        List {
            if instances.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    
                    Text("All caught up!")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("No chores waiting for approval.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } else {
                ForEach(instances) { instance in
                    ChoreApprovalCard(
                        instance: instance,
                        chore: chores[instance.choreId],
                        child: children[instance.assigneeChildId],
                        onApprove: { approveChore(instance) },
                        onReject: { rejectChore(instance) }
                    )
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private func approveChore(_ instance: ChoreInstance) {
        Task {
            try await choreService.approveChore(instance)
        }
    }
    
    private func rejectChore(_ instance: ChoreInstance) {
        Task {
            try await choreService.rejectChore(instance)
        }
    }
}

struct ChoreApprovalCard: View {
    let instance: ChoreInstance
    let chore: Chore?
    let child: AppUser?
    let onApprove: () -> Void
    let onReject: () -> Void
    
    @State private var showingPhotoDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(chore?.title ?? "Unknown Chore")
                        .font(.headline)
                    
                    if let child = child {
                        Text("by \(child.displayName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Completed \(instance.completedAt ?? Date(), style: .relative) ago")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let chore = chore {
                    VStack {
                        Image(systemName: "star.fill")
                            .font(.title2)
                            .foregroundColor(.yellow)
                        Text("\(chore.points)")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                }
            }
            
            // Photo if available
            if let photoURL = instance.photoURL {
                Button(action: { showingPhotoDetail = true }) {
                    AsyncImageView(url: photoURL)
                        .frame(height: 200)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                .accessibilityLabel("View completion photo")
            }
            
            // Description if available
            if let description = chore?.description {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: onReject) {
                    HStack {
                        Image(systemName: "x.circle")
                        Text("Reject")
                    }
                    .font(.headline)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.red, lineWidth: 2)
                    )
                }
                .accessibilityLabel("Reject chore completion")
                
                Button(action: onApprove) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Approve")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.green)
                    .cornerRadius(8)
                }
                .accessibilityLabel("Approve chore completion")
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .sheet(isPresented: $showingPhotoDetail) {
            if let photoURL = instance.photoURL {
                PhotoDetailView(photoURL: photoURL)
            }
        }
    }
}

struct RewardApprovalsView: View {
    let redemptions: [Redemption]
    let rewards: [String: Reward]
    let children: [String: AppUser]
    
    @EnvironmentObject var rewardsService: RewardsService
    
    var body: some View {
        List {
            if redemptions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("No requests yet")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("No reward redemptions waiting for approval.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } else {
                ForEach(redemptions) { redemption in
                    RewardApprovalCard(
                        redemption: redemption,
                        reward: rewards[redemption.rewardId],
                        child: children[redemption.childId],
                        onApprove: { approveRedemption(redemption) },
                        onReject: { rejectRedemption(redemption) }
                    )
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private func approveRedemption(_ redemption: Redemption) {
        Task {
            try await rewardsService.approveRedemption(redemption)
        }
    }
    
    private func rejectRedemption(_ redemption: Redemption) {
        Task {
            try await rewardsService.rejectRedemption(redemption)
        }
    }
}

struct RewardApprovalCard: View {
    let redemption: Redemption
    let reward: Reward?
    let child: AppUser?
    let onApprove: () -> Void
    let onReject: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reward?.title ?? "Unknown Reward")
                        .font(.headline)
                    
                    if let child = child {
                        Text("Requested by \(child.displayName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Requested \(redemption.requestedAt, style: .relative) ago")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let reward = reward {
                    VStack {
                        Image(systemName: "star.fill")
                            .font(.title2)
                            .foregroundColor(.yellow)
                        Text("\(reward.costPoints)")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                }
            }
            
            // Description if available
            if let description = reward?.description {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: onReject) {
                    HStack {
                        Image(systemName: "x.circle")
                        Text("Reject")
                    }
                    .font(.headline)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.red, lineWidth: 2)
                    )
                }
                .accessibilityLabel("Reject reward redemption")
                
                Button(action: onApprove) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Approve")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.green)
                    .cornerRadius(8)
                }
                .accessibilityLabel("Approve reward redemption")
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }
}

struct PhotoDetailView: View {
    let photoURL: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                AsyncImageView(url: photoURL)
                    .aspectRatio(contentMode: .fit)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}