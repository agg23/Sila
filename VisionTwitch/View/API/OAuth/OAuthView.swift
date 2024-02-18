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

    var body: some View {
        HStack(alignment: .top, content: {
            CloseButtonView {
                dismiss()
            }
            Spacer()
        })
        OAuthWebView(completed: self.receiveOAuthStatus)
        Text("Welcome to Oauth")
    }

    func receiveOAuthStatus(_ status: OAuthStatus) {
        switch status {
        case .success(token: let token):
            // Auth and try to get user ID. Set userId to empty string so Helix doesn't throw
            let helix = try! Helix(authentication: .init(oAuth: token, clientID: AuthController.CLIENT_ID, userId: ""))
            Task {
                let users = try? await helix.getUsers(userIDs: [], userLogins: [])
                guard let user = users?.first else {
                    print("Failed to get user in getUsers request")
                    return
                }

                // TODO: Get username, profile URL
                AuthController.shared.setCredientials(withToken: token, userId: user.id)

                print(user)
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
