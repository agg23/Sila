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

    var user: AuthUser?

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
