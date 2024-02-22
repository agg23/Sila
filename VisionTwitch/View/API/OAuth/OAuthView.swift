//
//  OAuthView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/17/24.
//

import SwiftUI
import Twitch

struct OAuthView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.authController) private var authController

    var body: some View {
        VStack(spacing: 0) {
            HStack(content: {
                CloseButtonView {
                    self.authController.logOut()
                    dismiss()
                }
                // Offset to prevent button from being cut off from rounded corners
                .padding(.leading, 32)
                Spacer()
            })
            .padding(.vertical, 12)
            OAuthWebView(completed: self.receiveOAuthStatus)
        }
        .frame(width: 800, height: 600)
    }

    func receiveOAuthStatus(_ status: OAuthStatus) {
        switch status {
        case .success(token: let token):
            // Auth and try to get user ID. Set userId to empty string so Helix doesn't throw
            let helix = try! Helix(authentication: .init(oAuth: token, clientID: AuthController.CLIENT_ID, userId: ""))
            Task {
                let users = try? await helix.getUsers(userIDs: [], userLogins: [])
                guard let user = users?.first else {
                    // TODO: Display error?
                    print("Failed to get user in getUsers request")
                    dismiss()
                    return
                }

                let authUser = AuthUser(id: user.id, username: user.displayName, avatarUrl: URL(string: user.profileImageUrl))

                self.authController.setLoggedInCredentials(withToken: token, authUser: authUser)
            }
        case .failure:
            print("Failed to oauth")
        }

        dismiss()
    }
}

#Preview {
    OAuthView()
}
