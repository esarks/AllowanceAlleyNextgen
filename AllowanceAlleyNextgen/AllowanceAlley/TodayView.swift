//
//  TodayView.swift
//  AllowanceAlleyNextgen
//
//  Created by Paul Marshall on 8/22/25.
//

import SwiftUI

/// Minimal child-centric "today" screen so the app compiles and runs.
/// You can flesh this out later with real assignments and points.
struct TodayView: View {
    let childId: String

    var body: some View {
        VStack(spacing: 16) {
            Text("Today")
                .font(.largeTitle).bold()

            Text("Child ID: \(childId)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            Text("This is a stub view.\nWire chores, points, and approvals here.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        }
        .padding()
    }
}

#Preview {
    TodayView(childId: "demo-child-123")
}
