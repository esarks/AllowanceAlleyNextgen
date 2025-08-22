//
//  RewardsShopView.swift
//  AllowanceAlley
//

import SwiftUI

struct RewardsShopView: View {
    @EnvironmentObject var rewardsService: RewardsService
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var familyService: FamilyService
    
    @State private var selectedChild: AppUser?
    @State private var childPointsBalance: [String: Int] = [:]
    @State private var showingRewardForm = false
    @State private var selectedReward: Reward?
    @State private var showingRedemptionConfirmation = false
    
    var isParent: Bool {
        authService.currentUser?.role == .parent
    }
    
    var currentChildId: String? {
        if isParent {
            return selectedChild?.id
        } else {
            return authService.currentUser?.id
        }
    }
    
    var currentChildBalance: Int {
        guard let childId = currentChildId else { return 0 }
        return childPointsBalance[childId] ?? 0
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rewards Shop")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if isParent {
                            Text("Manage family rewards")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Spend your points!")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if isParent {
                        Button("Add Reward") {
                            showingRewardForm = true
                        }
                        .font(.headline)
                        .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                
                // Child selector for parents
                if isParent && !familyService.children.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(familyService.children) { child in
                                ChildSelectorCard(
                                    child: child,
                                    pointsBalance: childPointsBalance[child.id] ?? 0,
                                    isSelected: selectedChild?.id == child.id
                                ) {
                                    selectedChild = child
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Points display
                if let childId = currentChildId,
                   let child = isParent ? selectedChild : authService.currentUser {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        
                        Text("\(child.displayName) has \(currentChildBalance) points")
                            .font(.headline)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.yellow.opacity(0.1))
                }
            }
            .background(Color.gray.opacity(0.05))
            
            // Rewards List
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(rewardsService.rewards.filter { $0.isActive }) { reward in
                        RewardCard(
                            reward: reward,
                            canAfford: currentChildBalance >= reward.costPoints,
                            isParent: isParent,
                            onRequest: { requestReward(reward) },
                            onEdit: { editReward(reward) },
                            onToggleActive: { toggleRewardActive(reward) }
                        )
                    }
                }
                .padding()
            }
            
            if rewardsService.rewards.filter({ $0.isActive }).isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "gift")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No rewards yet")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if isParent {
                        Text("Add some rewards to motivate your kids!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Add First Reward") {
                            showingRewardForm = true
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    } else {
                        Text("Ask your parents to add some rewards!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingRewardForm) {
            RewardFormView()
        }
        .alert("Request Reward", isPresented: $showingRedemptionConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Request") {
                if let reward = selectedReward, let childId = currentChildId {
                    Task {
                        try await rewardsService.requestRedemption(rewardId: reward.id, childId: childId)
                        await loadPointsBalances()
                    }
                }
            }
        } message: {
            if let reward = selectedReward {
                Text("Do you want to request '\(reward.title)' for \(reward.costPoints) points?")
            }
        }
        .onAppear {
            Task {
                try await rewardsService.loadRewards()
                await loadPointsBalances()
                
                // Auto-select first child for parents
                if isParent && selectedChild == nil && !familyService.children.isEmpty {
                    selectedChild = familyService.children.first
                }
            }
        }
    }
    
    private func loadPointsBalances() async {
        for child in familyService.children {
            let balance = await rewardsService.getPointsBalance(for: child.id)
            await MainActor.run {
                childPointsBalance[child.id] = balance
            }
        }
        
        // Also load for current child user if not parent
        if !isParent, let childId = authService.currentUser?.id {
            let balance = await rewardsService.getPointsBalance(for: childId)
            await MainActor.run {
                childPointsBalance[childId] = balance
            }
        }
    }
    
    private func requestReward(_ reward: Reward) {
        selectedReward = reward
        showingRedemptionConfirmation = true
    }
    
    private func editReward(_ reward: Reward) {
        // Implementation for editing rewards
        showingRewardForm = true
    }
    
    private func toggleRewardActive(_ reward: Reward) {
        Task {
            var updatedReward = reward
            updatedReward.isActive.toggle()
            try await rewardsService.updateReward(updatedReward)
        }
    }
}

struct ChildSelectorCard: View {
    let child: AppUser
    let pointsBalance: Int
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                Circle()
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(child.displayName.prefix(2)).uppercased())
                            .font(.headline)
                            .foregroundColor(isSelected ? .white : .primary)
                    )
                
                Text(child.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular)
                
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                    Text("\(pointsBalance)")
                        .font(.caption2)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(12)
        }
        .accessibilityLabel("Select \(child.displayName), \(pointsBalance) points")
    }
}

struct RewardCard: View {
    let reward: Reward
    let canAfford: Bool
    let isParent: Bool
    let onRequest: () -> Void
    let onEdit: () -> Void
    let onToggleActive: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(reward.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(2)
                
                Spacer()
                
                if isParent {
                    Menu {
                        Button(action: onEdit) {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(action: onToggleActive) {
                            Label(reward.isActive ? "Deactivate" : "Activate", 
                                  systemImage: reward.isActive ? "eye.slash" : "eye")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // Description
            if let description = reward.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            Spacer()
            
            // Points and action
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    
                    Text("\(reward.costPoints) points")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Spacer()
                }
                
                if !isParent {
                    Button(action: onRequest) {
                        Text(canAfford ? "Request" : "Need more points")
                            .font(.headline)
                            .foregroundColor(canAfford ? .white : .gray)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(canAfford ? Color.blue : Color.gray.opacity(0.3))
                            .cornerRadius(8)
                    }
                    .disabled(!canAfford)
                    .accessibilityLabel(canAfford ? "Request \(reward.title)" : "Not enough points for \(reward.title)")
                }
            }
        }
        .padding()
        .frame(height: 180)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct RewardFormView: View {
    @EnvironmentObject var rewardsService: RewardsService
    @EnvironmentObject var familyService: FamilyService
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var costPoints = ""
    @State private var isActive = true
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Reward Details") {
                    TextField("Title", text: $title)
                        .textContentType(.none)
                    
                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    TextField("Cost (Points)", text: $costPoints)
                        .keyboardType(.numberPad)
                    
                    Toggle("Active", isOn: $isActive)
                }
                
                Section("Examples") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Popular rewards:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("• Extra screen time (50 points)")
                        Text("• Choose dinner (75 points)")
                        Text("• Stay up late (100 points)")
                        Text("• Special outing (200 points)")
                        Text("• Small toy (300 points)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Add Reward")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveReward()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !title.isEmpty && !costPoints.isEmpty && Int(costPoints) != nil
    }
    
    private func saveReward() {
        guard let points = Int(costPoints),
              let family = familyService.currentFamily else {
            errorMessage = "Invalid input"
            return
        }
        
        let reward = Reward(
            familyId: family.id,
            title: title,
            description: description.isEmpty ? nil : description,
            costPoints: points,
            isActive: isActive
        )
        
        Task {
            do {
                try await rewardsService.createReward(reward)
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
}