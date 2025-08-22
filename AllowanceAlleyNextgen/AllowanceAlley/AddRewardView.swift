
import SwiftUI

struct AddRewardView: View {
    @EnvironmentObject var rewardsService: RewardsService
    @EnvironmentObject var authService: AuthService

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var costPoints = 50
    @State private var error: String?

    var body: some View {
        NavigationView {
            Form {
                Section("Reward Details") {
                    TextField("Reward name", text: $name)

                    HStack {
                        Text("Cost in points")
                        Spacer()
                        Stepper("\(costPoints)", value: $costPoints, in: 1...1000, step: 10)
                    }
                }

                Section("Examples") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Low cost (10-50 points):")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("Extra screen time, choose snack, stay up 15 min late")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Medium cost (50-150 points):")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("Choose dinner, friend sleepover, special outing")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("High cost (150+ points):")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("New toy, movie theater trip, special purchase")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let error {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("Add Reward")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveReward()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func saveReward() {
        guard let familyId = authService.currentUser?.familyId ?? authService.currentUser?.id else {
            error = "Authentication error"
            return
        }

        let reward = Reward(
            familyId: familyId,
            name: name,
            costPoints: costPoints
        )

        Task {
            do {
                try await rewardsService.createReward(reward)
                dismiss()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}
