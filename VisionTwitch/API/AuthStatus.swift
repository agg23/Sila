//
//  AuthStatus.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/21/24.
//

import Foundation
import Twitch

enum AuthStatus: Equatable {
    /// User is logged in
    case user(user: AuthUser, api: Helix)
    /// No user is logged in, but with have public token
    case publicLoggedOut(api: Helix)
    /// No access to Twitch API
    case none

    func api() -> Helix? {
        guard let (api, _) = apiAndUser() else {
            return nil
        }

        return api
    }

    func user() -> AuthUser? {
        guard let (_, user) = apiAndUser() else {
            return nil
        }

        return user
    }

    func apiAndUser() -> (Helix, AuthUser?)? {
        switch self {
        case .user(let user, let api):
            return (api, user)
        case .publicLoggedOut(let api):
            return (api, nil)
        case .none:
            return nil
        }
    }
}

struct AuthUser: Codable, Equatable {
    let id: String
    let username: String
    let avatarUrl: URL?
}
