//
//  AuthUser.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/18/24.
//

import Foundation

struct AuthUser: Codable {
    let id: String
    let username: String
    let avatarUrl: URL?
}
