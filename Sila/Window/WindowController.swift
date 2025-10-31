//
//  WindowController.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 3/6/24.
//

import Foundation
import Combine
import Twitch

class WindowController {
    class PlaybackWindowRecord {
        var muted = true
    }

    static let shared = WindowController()

    let allMuteSubject: PassthroughSubject<Bool, Never> = PassthroughSubject()
    let popoutChatSubject: PassthroughSubject<String, Never> = PassthroughSubject()

    /// Tracks whether there is currently a main window displayed
    var mainWindowSpawned = false

    private var playbackWindows: [String: PlaybackWindowRecord] = [:]
    /// Track all opened windows so we can forcibly close then when the main window opens
    private(set) var previouslyOpenedWindows = Set<Twitch.Stream>()

    var spawnedPlaybackCount: Int {
        get {
            self.playbackWindows.count
        }
    }

    /// Tracks the last opened playback window ID so it can be killed in some scenarios of launching the app from SpringBoard
    var lastPlaybackWindowsId: String?

    private init() {}

    /// Count the number of active playback windows, so we know when to spawn the main window
    func refPlaybackWindow(with stream: Twitch.Stream) {
        self.playbackWindows[stream.id] = PlaybackWindowRecord()
        self.previouslyOpenedWindows.insert(stream)
    }

    /// Dereference this active playback window, so we know when to spawn the main window
    /// Returns true if there are no registered windows
    func derefPlaybackWindow(with id: String) {
        self.playbackWindows.removeValue(forKey: id)
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
