//
//  Window.swift
//  Sila
//
//  Created by Adam Gastineau on 10/29/25.
//

import Foundation

struct Window {
    static let stream = "stream"
    static let vod = "vod"
    static let chat = "chat"
    static let followerStream = "immersiveFollowerStream"

    static let smallWindowCornerRadius = 24.0
    static let largeWindowCornerRadius = 48.0
}

struct WindowModel: Hashable, Codable {
    let id: UUID

    let router: Router

    init(router: Router?) {
        self.id = UUID()
        self.router = router ?? Router()
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}
