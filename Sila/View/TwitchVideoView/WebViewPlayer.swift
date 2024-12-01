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
    let duration: Double
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
    // Track video (VoD) status for quality hack (see below)
    var isVideo: Bool = false

    var status: PlaybackStatus = .idle

    var currentTime: Double
    var duration: Double

    var seekDebounceTimer: Timer?
    var seekDebounceTime: Double

    var muted: Bool = true
    var volume: Double = 0.0

    var channel: String? = nil
    var channelId: String? = nil
    var quality: String = "auto"
    var availableQualities: [VideoQuality] = []
    var maxVideoQuality: VideoQuality?

    weak var webView: WKWebView?

    init() {
        self.currentTime = 0.0
        self.duration = 0.0
        self.seekDebounceTime = 0.0

        self.volume = SharedPlaybackSettings.getVolume()
        self.quality = SharedPlaybackSettings.getQuality()

        NotificationCenter.default.addObserver(forName: .twitchMuteAll, object: nil, queue: nil) { notification in
            print("Setting mute all")
            self.setMute(true)
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

    func seek(_ time: Double) {
        self.seekDebounceTime = time
        self.currentTime = time

        if (self.seekDebounceTimer == nil) {
            self.startSeekDebounceTimer()
        }
    }

    private func seekImmediate(_ time: Double) {
        self.webView?.evaluateJavaScript("""
            Twitch._player.seek(\(time));
        """)
    }

    func startSeekDebounceTimer() {
        // TODO: This doesn't handle correctly if the video keeps playing while seeking
        self.seekDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { timer in
            timer.invalidate()
            self.seekDebounceTimer = nil

            self.seekImmediate(self.seekDebounceTime)
        })
    }

    func toggleMute() {
        self.setMute(!self.muted)
    }

    func setMute(_ mute: Bool) {
        self.webView?.evaluateJavaScript("""
            Twitch._player.setMuted(\(mute));
        """)
    }

    func setVolume(_ volume: Double) {
        self.webView?.evaluateJavaScript("""
            if (\(self.muted)) {
                Twitch._player.setMuted(false);
            }

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

    func setIsVideo(_ isVideo: Bool) {
        self.isVideo = isVideo
    }

    func applyEvent(_ event: TwitchEvent) {
        self.currentTime = event.currentTime
        self.duration = event.duration
        
        // Mark low enough volume as muted as well
        self.muted = event.muted || event.volume < 0.01
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

        // If we are viewing a VoD and have not set max quality, on first instance of availableQualities, force quality to the highest value
        // This prevents VoDs not playing back depending on quality on Vision (including in Safari)
        if self.isVideo && self.maxVideoQuality == nil && self.availableQualities.count > 0 {
            if let maxQuality = self.availableQualities.filter({ $0.quality != "auto" }).first {
                self.maxVideoQuality = maxQuality
                self.setQuality(maxQuality.quality)
            }
        }

        SharedPlaybackSettings.setVolume(self.volume)

        if self.isVideo {
            // Don't save last selected quality when playing back VoD
            SharedPlaybackSettings.setQuality(self.quality)
        }
    }
}
