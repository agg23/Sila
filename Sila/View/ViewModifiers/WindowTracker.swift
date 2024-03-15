//
//  WindowTracker.swift
//  Sila
//
//  Created by Eric Lewis on 3/15/24.
//

import SwiftUI
import Twitch

enum WindowTrackerParams {
    case main
    case playback(stream: Twitch.Stream)
}

struct WindowTrackerViewModifier: ViewModifier {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    let state: WindowTrackerParams

    func body(content: Content) -> some View {
        content
            .mount {
                switch self.state {
                case .main:
                    WindowController.shared.mainWindowSpawned = true
                    for id in WindowController.shared.previouslyOpenedWindows {
                        // If we are spawning the main window, that means there should be no players
                        // Thanks to a bug (as of 1.1), there may be phantom windows hanging around
                        // Kill any possible window
                        dismissWindow(id: "stream", value: id)
                    }
                case .playback(let stream):
                    WindowController.shared.refPlaybackWindow(with: stream)
                    NotificationCenter.default.post(name: .twitchMuteAll, object: nil, userInfo: nil)
                }
            } unmount: {
                switch self.state {
                case .main:
                    WindowController.shared.mainWindowSpawned = false
                case .playback(let stream):
                    WindowController.shared.derefPlaybackWindow(with: stream.id)

                    if WindowController.shared.spawnedPlaybackCount < 1 && !WindowController.shared.mainWindowSpawned {
                        // Spawn main window
                        openWindow(value: "main")
                    }
                }
            }
    }
}

extension View {
    func mainWindow() -> some View {
        self.modifier(WindowTrackerViewModifier(state: .main))
    }

    func playbackWindow(for stream: Twitch.Stream) -> some View {
        self.modifier(WindowTrackerViewModifier(state: .playback(stream: stream)))
    }
}
