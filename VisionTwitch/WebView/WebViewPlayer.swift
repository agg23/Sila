//
//  WebViewPlayer.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/7/24.
//

import Foundation
import Combine
import WebKit

enum PlaybackStatus {
    case playing
    case idle
    case buffering
    case ready
}

struct TwitchEvent {
    let currentTime: Double
    let muted: Bool
    let playback: PlaybackStatus
    let volume: Double
}

class WebViewPlayer: ObservableObject {
    @Published var status: PlaybackStatus = .idle

    @Published var muted: Bool = true
    @Published var volume: Double = 0.0

    var functionCaller = PassthroughSubject<String, Never>()

    var isPlaying: Bool {
        get {
            return status == .buffering || status == .playing
        }
    }

    func play() {
        self.functionCaller.send("""
            Twitch._player.play();
        """)
    }

    func pause() {
        self.functionCaller.send("""
            Twitch._player.pause();
        """)
    }

    func toggleMute() {
        self.muted = !self.muted;
        self.functionCaller.send("""
            Twitch._player.setMuted(\(self.muted));
        """)
    }

    func applyEvent(_ event: TwitchEvent) {
        // TODO: Handle currentTime
        self.muted = event.muted
        self.status = event.playback
        self.volume = event.volume
    }
}
