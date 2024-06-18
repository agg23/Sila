//
//  Emote.swift
//  Sila
//
//  Created by Adam Gastineau on 4/15/24.
//

import Foundation

class Emote {
    let name: String

    let imageUrl: URL

    let source: EmoteSource

    init(name: String, imageUrl: URL, source: EmoteSource) {
        self.name = name
        self.imageUrl = imageUrl
        self.source = source
    }

    func isHigherPriority(than source: EmoteSource) -> Bool {
        self.source.rawValue > source.rawValue
    }
}

enum EmoteSource: Int {
    case sevenTV = 2
    case betterTTV = 1
    case frankerFaceZ = 0
}
