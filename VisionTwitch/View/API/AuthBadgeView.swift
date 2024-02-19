//
//  AuthBadgeView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/17/24.
//

import SwiftUI
import Combine

struct AuthBadgeView: View {
    @State var authUser = AuthUserProvider()
    @State var showOauth = false

    var body: some View {
        Menu {
            if let authUser = self.authUser.user, AuthController.shared.isAuthorized {
                Button("Logged In: \(authUser.username)") {}
                    .disabled(/*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                Button("Log Out") {
                    AuthController.shared.logOut()
                }
            } else {
                Button("Log In") {
                    self.showOauth = true
                }
            }
        } label: {
            Image(systemName: "person.circle")
                .imageScale(.large)
        }
        .onReceive(AuthController.shared.requestReauthSubject) { _ in
            // We need to reauth
            self.showOauth = true
        }
        .buttonBorderShape(.circle)
        .sheet(isPresented: $showOauth) {
            OAuthView()
        }
    }
}

@Observable class AuthUserProvider {
    private var cancellables = Set<AnyCancellable>()

    // Make sure to initialize to current state
    var user: AuthUser? = AuthController.shared.authUser

    init() {
        AuthController.shared.authChangeSubject.sink { _ in
        } receiveValue: { _ in
            self.user = AuthController.shared.authUser
        }.store(in: &self.cancellables)
    }
}

#Preview {
    AuthBadgeView()
}
