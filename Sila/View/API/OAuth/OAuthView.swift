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
    @Environment(AuthController.self) private var authController

    @State private var isLoading: Bool = true

    var body: some View {
        NavigationStack {
            OAuthWebView(setIsLoading: {
                isLoading = $0
            }, completed: self.receiveOAuthStatus)
                .ignoresSafeArea()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        CloseButtonView {
                            self.authController.logOut()
                            dismiss()
                        }
                    }
                }
                .blur(radius: isLoading ? 10 : 0)
                .overlay {
                    if isLoading {
                        ProgressView()
                            .controlSize(.large)
                    }
                }
        }
        .frame(width: 800, height: 600)
    }

    func receiveOAuthStatus(_ status: OAuthStatus) {
        switch status {
        case .success(token: let token):
            // Auth and try to get user ID. Set userId to empty string so Helix doesn't throw
            let client = TwitchClient(authentication: .init(oAuth: token, clientID: AuthController.CLIENT_ID, userID: "", userLogin: ""))
            Task {
                let users = try? await client.helix(endpoint: .getUsers(ids: [], names: []))
                guard let user = users?.first else {
                    // TODO: Display error?
                    print("Failed to get user in getUsers request")
                    dismiss()
                    return
                }

                let authUser = AuthUser(id: user.id, username: user.displayName, avatarUrl: URL(string: user.profileImageUrl))

                DispatchQueue.main.async {
                    self.authController.setLoggedInCredentials(withToken: token, authUser: authUser)
                }
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
