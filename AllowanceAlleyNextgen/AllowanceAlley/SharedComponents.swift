//
//  SharedComponents.swift
//  AllowanceAlleyNextgen
//
//  Created by Paul Marshall on 8/22/25.
//

import SwiftUI

// MARK: - Shared UI Components

struct StatCard: View {
    let title: String
    let completed: Int
    let total: Int
    let color: Color

    var body: some View {
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

struct ChildSummaryCard: View {
    let child: Child
    @EnvironmentObject var rewardsService: RewardsService
    @State private var pointsBalance = 0

    var body: some View {
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

                Text("0 completed") // TODO: Get actual completions
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

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
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
