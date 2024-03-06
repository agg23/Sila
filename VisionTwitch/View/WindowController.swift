//
//  WindowController.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 3/6/24.
//

import Foundation

class WindowController {
    static let shared = WindowController()

    var mainWindowSpawned = false
    private(set) var playbackWindowSpawnedCount = 0

    private init() {}

    func refPlaybackWindow() {
        self.playbackWindowSpawnedCount += 1
    }

    func derefPlaybackWindow() -> Bool {
        guard self.playbackWindowSpawnedCount > 0 else {
            return false
        }

        self.playbackWindowSpawnedCount -= 1

        return self.playbackWindowSpawnedCount == 0
    }
}
