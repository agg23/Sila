//
//  AuthBadgeView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/17/24.
//

import SwiftUI
import Combine

struct AuthBadgeView: View {
    @Environment(AuthController.self) private var authController

    @State var showOauth = false

    var body: some View {
        Menu("Account", systemImage: "person.fill") {
            if let authUser = self.authController.status.user() {
                Button("Logged In: \(authUser.username)") {}
                    .disabled(/*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                Button("Log Out") {
                    self.authController.logOut()
                }
            } else {
                Button("Log In") {
                    self.showOauth = true
                }
            }
        }
        // Force rounded icon on vision 2.0+
        .menuStyle(.borderlessButton)
        .onReceive(self.authController.requestReauthSubject) { _ in
            // We need to reauth
            self.showOauth = true
        }
        .sheet(isPresented: $showOauth) {
            OAuthView()
        }
    }
}

#Preview {
    NavigationStack {
        Text("hi")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    AuthBadgeView()
                }
            }
    }
}
