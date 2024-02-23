//
//  UserWrapper.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/19/24.
//

import Foundation
import Twitch

enum UserWrapper {
    case user(_ user: User)
    case id(_ id: String)
}

extension UserWrapper: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .user(let user):
            hasher.combine("user")
            hasher.combine(user.id)
        case .id(let id):
            hasher.combine("id")
            hasher.combine(id)
        }
    }

    static func == (lhs: UserWrapper, rhs: UserWrapper) -> Bool {
        switch (lhs, rhs) {
        case (.user(let leftUser), .user(let rightUser)):
            return leftUser.id == rightUser.id
        case (.id(let leftId), .id(let rightId)):
            return leftId == rightId
        default:
            return false
        }
    }
}
