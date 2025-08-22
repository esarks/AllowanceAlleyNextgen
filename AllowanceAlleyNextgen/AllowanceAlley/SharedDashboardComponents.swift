
import SwiftUI

// MARK: - Shared Dashboard Components
// Single source of truth to avoid 'Invalid redeclaration' errors.

public struct StatCard: View {
    public let title: String
    public let completed: Int
    public let total: Int
    public let color: Color

    public init(title: String, completed: Int, total: Int, color: Color) {
        self.title = title
        self.completed = completed
        self.total = total
        self.color = color
    }

    public var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text("\(completed)/\(total)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            ProgressView(value: total > 0 ? Double(completed) / Double(total) : 0)
                .tint(color)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

public struct ChildSummaryCard: View {
    public let child: Child
    @EnvironmentObject var rewardsService: RewardsService
    @State private var pointsBalance = 0

    public init(child: Child) {
        self.child = child
    }

    public var body: some View {
        HStack {
            Circle()
                .fill(Color.blue.gradient)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(child.name.prefix(1)))
                        .font(.headline)
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(child.name)
                    .font(.headline)

                if let age = child.age {
                    Text("Age \(age)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(pointsBalance) points")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)

                Text("0 completed") // TODO: wire completions
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .task {
            pointsBalance = await rewardsService.getPointsBalance(for: child.id)
        }
    }
}

public struct QuickActionButton: View {
    public let icon: String
    public let title: String
    public let color: Color
    public let action: () -> Void

    public init(icon: String, title: String, color: Color, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.color = color
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}
