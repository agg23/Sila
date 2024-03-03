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

    let channelId: String?
    let channel: String?
    let quality: String
    let availableQualities: [VideoQuality]
}

struct VideoQuality {
    let quality: String
    let name: String
}

@Observable class WebViewPlayer {
    var status: PlaybackStatus = .idle

    var muted: Bool = true
    var volume: Double = 0.0

    var channel: String? = nil
    var channelId: String? = nil
    var quality: String = "auto"
    var availableQualities: [VideoQuality] = []

    weak var webView: WKWebView?

    init() {
        self.volume = SharedPlaybackSettings.getVolume()
        self.quality = SharedPlaybackSettings.getQuality()

        NotificationCenter.default.addObserver(forName: .twitchMuteAll, object: nil, queue: nil) { notification in
            self.webView?.evaluateJavaScript("""
                let video = document.getElementsByTagName("video");
                if (video.length > 0) {
                    video[0].muted = true;
                }
            """)
        }

        let _ = withObservationTracking {
            self.volume
        } onChange: {
            self.setVolume(self.volume)
        }
    }

    var isPlaying: Bool {
        get {
            return status == .buffering || status == .playing
        }
    }

    func play() {
        self.webView?.evaluateJavaScript("""
            Twitch._player.play();
        """)
    }

    func pause() {
        self.webView?.evaluateJavaScript("""
            Twitch._player.pause();
        """)
    }

    func toggleMute() {
        self.webView?.evaluateJavaScript("""
            Twitch._player.setMuted(\(!self.muted));
        """)
    }

    func setVolume(_ volume: Double) {
        self.webView?.evaluateJavaScript("""
            Twitch._player.setVolume(\(volume));
        """)
    }

    func setQuality(_ quality: String) {
        self.webView?.evaluateJavaScript("""
            Twitch._player.setQuality("\(quality)");
        """)
    }

    func reload() {
        self.webView?.reload()
    }

    func applyEvent(_ event: TwitchEvent) {
        // TODO: Handle currentTime
        self.muted = event.muted
        self.status = event.playback
        self.volume = event.volume

        if let channelId = event.channelId {
            self.channelId = channelId
        }

        if let channel = event.channel {
            self.channel = channel
        }

        self.quality = event.quality
        self.availableQualities = event.availableQualities

        SharedPlaybackSettings.setVolume(self.volume)
        SharedPlaybackSettings.setQuality(self.quality)
    }
}
