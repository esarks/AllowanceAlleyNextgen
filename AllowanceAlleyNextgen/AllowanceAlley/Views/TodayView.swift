//
//  TodayView.swift
//  AllowanceAlley
//

import SwiftUI

struct TodayView: View {
    let childId: String
    
    @EnvironmentObject var choreService: ChoreService
    @EnvironmentObject var rewardsService: RewardsService
    @EnvironmentObject var familyService: FamilyService
    @EnvironmentObject var imageStore: ImageStore
    @EnvironmentObject var authService: AuthService
    
    @State private var todayInstances: [ChoreInstance] = []
    @State private var chores: [String: Chore] = [:]
    @State private var pointsBalance = 0
    @State private var selectedInstance: ChoreInstance?
    @State private var showingPhotoCapture = false
    @State private var capturedImage: UIImage?
    @State private var showingPointsHistory = false
    
    var child: AppUser? {
        familyService.children.first { $0.id == childId }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        if let child = child {
                            HStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Text(String(child.displayName.prefix(2)).uppercased())
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    )
                                
                                VStack(alignment: .leading) {
                                    Text("Hi \(child.displayName)!")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    
                                    Button(action: { showingPointsHistory = true }) {
                                        HStack {
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.yellow)
                                            Text("\(pointsBalance) points")
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                        }
                                    }
                                    .accessibilityLabel("View points history. Current balance: \(pointsBalance) points")
                                }
                                
                                Spacer()
                                
                                Button("Sign Out") {
                                    Task {
                                        try await authService.signOut()
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                        }
                        
                        // Today's Progress
                        let completedCount = todayInstances.filter { $0.status == .approved }.count
                        let totalCount = todayInstances.count
                        
                        VStack(spacing: 8) {
                            Text("Today's Chores")
                                .font(.headline)
                            
                            if totalCount > 0 {
                                ProgressView(value: Double(completedCount), total: Double(totalCount))
                                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                                
                                Text("\(completedCount) of \(totalCount) completed")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("No chores for today! 🎉")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Chore List
                    LazyVStack(spacing: 12) {
                        ForEach(todayInstances) { instance in
                            ChoreInstanceCard(
                                instance: instance,
                                chore: chores[instance.choreId],
                                onComplete: { completeChore(instance) },
                                onAddPhoto: {
                                    selectedInstance = instance
                                    showingPhotoCapture = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    if todayInstances.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                            
                            Text("All done for today!")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Great job! Check back tomorrow for new chores.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    }
                    
                    Spacer(minLength: 100)
                }
            }
            .navigationBarHidden(true)
            .refreshable {
                await loadTodayData()
            }
        }
        .sheet(isPresented: $showingPhotoCapture) {
            PhotoCaptureView(
                image: $capturedImage,
                onSave: { image in
                    if let instance = selectedInstance {
                        submitPhotoForChore(instance, image: image)
                    }
                }
            )
        }
        .sheet(isPresented: $showingPointsHistory) {
            PointsHistoryView(childId: childId, pointsBalance: pointsBalance)
        }
        .onAppear {
            Task {
                await loadTodayData()
            }
        }
    }
    
    private func loadTodayData() async {
        // Load chore instances
        await choreService.loadChoreInstances()
        todayInstances = choreService.getTodayInstances(for: childId)
        
        // Load chore details
        try? await choreService.loadChores()
        chores = Dictionary(uniqueKeysWithValues: choreService.chores.map { ($0.id, $0) })
        
        // Load points balance
        pointsBalance = await rewardsService.getPointsBalance(for: childId)
    }
    
    private func completeChore(_ instance: ChoreInstance) {
        guard let chore = chores[instance.choreId] else { return }
        
        if chore.requiresPhoto && instance.photoURL == nil {
            selectedInstance = instance
            showingPhotoCapture = true
        } else {
            Task {
                try await choreService.completeChore(instance)
                await loadTodayData()
            }
        }
    }
    
    private func submitPhotoForChore(_ instance: ChoreInstance, image: UIImage) {
        Task {
            do {
                let photoURL = try await imageStore.uploadImage(image)
                try await choreService.completeChore(instance, photoURL: photoURL)
                await loadTodayData()
            } catch {
                print("Failed to submit photo: \(error)")
            }
        }
    }
}

struct ChoreInstanceCard: View {
    let instance: ChoreInstance
    let chore: Chore?
    let onComplete: () -> Void
    let onAddPhoto: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Status Icon
            Button(action: onComplete) {
                Image(systemName: instance.status.systemImage)
                    .font(.title2)
                    .foregroundColor(instance.status.color)
                    .frame(width: 44, height: 44)
                    .background(instance.status.color.opacity(0.1))
                    .clipShape(Circle())
            }
            .disabled(instance.status != .assigned)
            .accessibilityLabel("Complete chore")
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(chore?.title ?? "Unknown Chore")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if let chore = chore {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text("\(chore.points)")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(4)
                    }
                }
                
                if let description = chore?.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    // Due time
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text("Due \(instance.dueAt, style: .time)")
                            .font(.caption)
                    }
                    .foregroundColor(instance.isOverdue ? .red : .secondary)
                    
                    Spacer()
                    
                    // Photo requirement
                    if chore?.requiresPhoto == true {
                        Button(action: onAddPhoto) {
                            HStack(spacing: 4) {
                                Image(systemName: instance.photoURL != nil ? "camera.fill" : "camera")
                                    .font(.caption)
                                Text(instance.photoURL != nil ? "Photo added" : "Add photo")
                                    .font(.caption)
                            }
                            .foregroundColor(.blue)
                        }
                        .accessibilityLabel(instance.photoURL != nil ? "Photo added" : "Add photo for chore")
                    }
                    
                    // Status badge
                    Text(instance.status.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(instance.status.color.opacity(0.2))
                        .foregroundColor(instance.status.color)
                        .cornerRadius(4)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct PhotoCaptureView: View {
    @Binding var image: UIImage?
    let onSave: (UIImage) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                    
                    Button("Use This Photo") {
                        onSave(image)
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(12)
                    .padding(.horizontal)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Take a photo to prove you completed this chore!")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        
                        VStack(spacing: 12) {
                            Button(action: {
                                sourceType = .camera
                                showingImagePicker = true
                            }) {
                                HStack {
                                    Image(systemName: "camera")
                                    Text("Take Photo")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                            
                            Button(action: {
                                sourceType = .photoLibrary
                                showingImagePicker = true
                            }) {
                                HStack {
                                    Image(systemName: "photo.on.rectangle")
                                    Text("Choose from Library")
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
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Add Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if image != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Retake") {
                            image = nil
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $image, sourceType: sourceType)
        }
    }
}

struct PointsHistoryView: View {
    let childId: String
    let pointsBalance: Int
    
    @EnvironmentObject var rewardsService: RewardsService
    @Environment(\.dismiss) var dismiss
    
    @State private var pointsHistory: [PointsLedger] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Points Header
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "star.fill")
                            .font(.title)
                            .foregroundColor(.yellow)
                        
                        Text("\(pointsBalance)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("points")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Great job earning points!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                
                // History List
                List(pointsHistory) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.reason)
                                .font(.headline)
                            
                            Text(entry.createdAt, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(entry.deltaPoints > 0 ? "+" : "")\(entry.deltaPoints)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(entry.deltaPoints > 0 ? .green : .red)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Points History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            pointsHistory = rewardsService.getPointsHistory(for: childId)
        }
    }
}