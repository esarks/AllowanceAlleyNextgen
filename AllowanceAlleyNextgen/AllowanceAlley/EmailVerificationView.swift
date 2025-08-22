//
//  EmailVerificationView.swift
//  AllowanceAlleyNextgen
//
//  Created by Paul Marshall on 8/22/25.
//

import SwiftUI

struct EmailVerificationView: View {
    @EnvironmentObject var authService: AuthService
    var body: some View {
        VStack(spacing: 16) {
            Text("Verify your email").font(.title2).bold()
            if let email = authService.pendingVerificationEmail {
                Text("We sent a verification link to\n\(email)").multilineTextAlignment(.center)
            }
            Text("After you verify, return to the app.")
            Button("I’ve verified — continue") {
                Task { await authService.initialize() }
            }
        }.padding()
    }
}
