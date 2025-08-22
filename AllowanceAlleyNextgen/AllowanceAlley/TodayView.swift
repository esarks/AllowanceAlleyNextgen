//
//  TodayView.swift
//  AllowanceAlleyNextgen
//
//  Created by Paul Marshall on 8/22/25.
//

import SwiftUI

/// Placeholder view so the app compiles.
/// Replace this with your real dashboard or home screen.
struct TodayView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("TodayView")
                .font(.largeTitle)
                .bold()
            Text("This is just a stub. Replace with your real dashboard.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    TodayView()
}
