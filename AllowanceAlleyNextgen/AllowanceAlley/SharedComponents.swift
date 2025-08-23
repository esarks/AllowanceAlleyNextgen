import SwiftUI

// Small card used on the dashboard
struct StatCard: View {
    let title: String
    let completed: Int
    let total: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline).foregroundColor(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(completed)").font(.title2).fontWeight(.bold)
                Text("/ \(total)").foregroundColor(.secondary)
            }
            ProgressView(value: total == 0 ? 0 : Double(completed) / Double(max(total, 1)))
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
        .background(color.opacity(0.12))
        .cornerRadius(12)
    }
}

// Square action button used in the grid
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 84)
            .padding(.vertical, 8)
            .background(color.opacity(0.12))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// Row showing a child summary (name + placeholder stats)
struct ChildSummaryCard: View {
    let child: Child

    var body: some View {
        HStack(spacing: 12) {
            Circle().fill(Color.blue.opacity(0.15)).frame(width: 40, height: 40)
                .overlay(Image(systemName: "person.fill").foregroundColor(.blue))
            VStack(alignment: .leading, spacing: 4) {
                Text(child.name) // assumes your Child model exposes `name`
                    .font(.headline)
                Text("Tap a quick action to assign chores or rewards")
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}
