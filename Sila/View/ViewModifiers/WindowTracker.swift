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

// TODO: Remove completely after the introduction of .defaultLaunchBehavior()
struct WindowTrackerViewModifier: ViewModifier {
    let state: WindowTrackerParams

    func body(content: Content) -> some View {
        content
            .mount {
                switch self.state {
                case .main:
                    WindowController.shared.mainWindowSpawned = true
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
