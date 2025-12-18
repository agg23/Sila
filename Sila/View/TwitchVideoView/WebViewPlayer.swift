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

// Equatable is required for setting the availableQualities array. This prevents constant invalidation of the SwiftUI state
struct VideoQuality: Equatable {
    let quality: String
    let name: String
}

struct OnEventContinuation: Identifiable, Equatable {
    let id: UUID = UUID()
    let continuation: CheckedContinuation<Bool, Never>
    let predicate: (TwitchEvent) -> Bool

    var timer: Timer? = nil

    init(continuation: CheckedContinuation<Bool, Never>, predicate: @escaping (TwitchEvent) -> Bool) {
        self.continuation = continuation
        self.predicate = predicate

        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { _ in
            print("Timing out predicate")
            continuation.resume(returning: false)
        })
    }

    func success() {
        self.continuation.resume(returning: true)
    }

    static func == (lhs: OnEventContinuation, rhs: OnEventContinuation) -> Bool {
        lhs.id == rhs.id
    }
}

@Observable class WebViewPlayer {
    @ObservationIgnored var queuedContinuations: [OnEventContinuation] = []

    // Track video (VoD) status for quality hack (see below)
    var isVideo: Bool = false

    var status: PlaybackStatus = .idle

    var currentTime: Double
    var duration: Double

    var seekDebounceTimer: Timer?
    var seekDebounceTime: Double

    var loading: Bool = false
    var muted: Bool = true
    var volume: Double = 0.0

    var channel: String? = nil
    var channelId: String? = nil
    var quality: String = "auto"
    var availableQualities: [VideoQuality] = []
    var maxVideoQuality: VideoQuality?

    var webView: WKWebView?

    init() {
        self.currentTime = 0.0
        self.duration = 0.0
        self.seekDebounceTime = 0.0

        self.volume = SharedPlaybackSettings.getVolume()
        self.quality = SharedPlaybackSettings.getQuality()


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
            try {
                Twitch._player.play();
            } catch (e) {
                console.error(`Failed to play: ${e}`);
            }
        """)
    }

    func playAndMuteOthers(except streamableVideo: StreamableVideo) {
        self.playAndMuteOthers(except: PlaybackPresentableController.contentId(for: streamableVideo))
    }

    func playAndMuteOthers(except contentId: String) {
        Task {
            await PlaybackPresentableController.muteAll(except: contentId)

            await MainActor.run {
                self.play()
            }
        }
    }

    func pause() {
        self.webView?.evaluateJavaScript("""
            try {
                Twitch._player.pause();
            } catch (e) {
                console.error(`Failed to pause: ${e}`);
            }
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
            try {
                Twitch._player.seek(\(time));
            } catch (e) {
                console.error(`Failed to seek: ${e}`);
            }
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

    func toggleMute() async -> Bool {
        await self.setMute(!self.muted)
    }

    func setMute(_ mute: Bool) async -> Bool {
        await self.awaitJavaScriptContinuation("""
            try {
                Twitch._player.setMuted(\(mute));
            } catch (e) {
                console.error(`Failed to set muted: ${e}`);
            }
        """) { event in
            event.muted == mute
        }
    }

    func awaitJavaScriptContinuation(_ script: String, predicate: @escaping (TwitchEvent) -> Bool) async -> Bool {
        var onEventContinuation: OnEventContinuation? = nil
        let result = await withCheckedContinuation { continuation in
            Task {
                await MainActor.run {
                    self.webView?.evaluateJavaScript(script, completionHandler: nil)
                }
            }

            let newContinuation = OnEventContinuation(continuation: continuation, predicate: predicate)
            self.queuedContinuations.append(newContinuation)
            onEventContinuation = newContinuation
        }

        // Continuation completed, clean up
        self.queuedContinuations.removeAll { $0 == onEventContinuation }
        return result
    }

    func setVolume(_ volume: Double) {
        self.webView?.evaluateJavaScript("""
            try {
                if (\(self.muted)) {
                    Twitch._player.setMuted(false);
                }

                Twitch._player.setVolume(\(volume));
            } catch (e) {
                console.error(`Failed to set volume: ${e}`);
            }
        """)
    }

    func setQuality(_ quality: String) {
        self.webView?.evaluateJavaScript("""
            try {
                Twitch._player.setQuality("\(quality)");
            } catch (e) {
                console.error(`Failed to set quality: ${e}`);
            }
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
        // Equatable on VideoQuality prevents constant SwiftUI invalidation
        self.availableQualities = event.availableQualities.map({ quality in
            if quality.quality == "auto" {
                VideoQuality(quality: quality.quality, name: "Automatic")
            } else {
                VideoQuality(quality: quality.quality, name: quality.name.replacingOccurrences(of: "(source)", with: "(Source)"))
            }
        })

        // If we are viewing a VoD and have not set max quality, on first instance of availableQualities, force quality to the highest value
        // This prevents VoDs not playing back depending on quality on Vision (including in Safari)
        if self.isVideo && self.maxVideoQuality == nil && self.availableQualities.count > 0 {
            if let maxQuality = self.availableQualities.filter({ $0.quality != "auto" }).first {
                self.maxVideoQuality = maxQuality
                self.setQuality(maxQuality.quality)
            }
        }

        for continuation in self.queuedContinuations {
            if continuation.predicate(event) {
                continuation.success()
            }
        }

        SharedPlaybackSettings.setVolume(self.volume)

        if self.isVideo {
            // Don't save last selected quality when playing back VoD
            SharedPlaybackSettings.setQuality(self.quality)
        }
    }
}
