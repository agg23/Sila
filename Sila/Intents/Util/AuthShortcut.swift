//
//  AuthShortcut.swift
//  Sila
//
//  Created by Adam Gastineau on 3/19/24.
//

import Twitch

struct AuthShortcut {
    static func getAPI(_ authController: AuthController) throws -> Helix {
        switch authController.status {
        case .user(_, let api):
            return api
        case .publicLoggedOut(let api):
            return api
        case .none:
            throw IntentError.unauthorized
        }
    }
}
