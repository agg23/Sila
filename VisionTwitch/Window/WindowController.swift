//
//  WindowController.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 3/6/24.
//

import Foundation
import Combine

class WindowController {
    class PlaybackWindowRecord {
        var muted = false
    }

    static let shared = WindowController()

    let allMuteSubject: PassthroughSubject<Bool, Never> = PassthroughSubject()

    /// Tracks whether there is currently a main window displayed
    var mainWindowSpawned = false

    private var playbackWindows: [String: PlaybackWindowRecord] = [:]

    private init() {}

    /// Count the number of active playback windows, so we know when to spawn the main window
    func refPlaybackWindow(with id: String) {
        self.playbackWindows[id] = PlaybackWindowRecord()
    }

    /// Dereference this active playback window, so we know when to spawn the main window
    /// Returns true if there are no registered windows
    func derefPlaybackWindow(with id: String) -> Bool {
        self.playbackWindows.removeValue(forKey: id)

        return self.playbackWindows.isEmpty
    }

    /// Set an active playback window's mute status
    func setPlaybackMuted(with id: String, muted: Bool) {
        guard let window = self.playbackWindows[id] else {
            print("Could not find playback window with id \(id)")
            return
        }

        window.muted = muted

        self.allMuteSubject.send(self.checkAllMuted())
    }

    func checkAllMuted() -> Bool {
        return self.playbackWindows.reduce(true) { prev, record in
            return prev && record.value.muted
        }
    }
}
