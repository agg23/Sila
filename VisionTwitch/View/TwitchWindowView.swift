//
//  TwitchWindowView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/18/24.
//

import SwiftUI
import Twitch

struct TwitchWindowView: View {
    @Environment(\.scenePhase) private var scene

    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    @State private var player = WebViewPlayer()

    @State private var delayLoading = !WindowController.shared.checkAllMuted()

    let streamableVideo: StreamableVideo

    var body: some View {
        TwitchVideoView(streamableVideo: self.streamableVideo, delayLoading: self.delayLoading, player: self.$player)
            // Set aspect ratio and enforce uniform resizing
//            .windowGeometryPreferences(minimumSize: CGSize(width: 160.0, height: 90.0), resizingRestrictions: .uniform)
            // Having the overlay hidden all of the time has the intended interaction of opening and closing
            // The only issue is the grabber is not constantly visible while the video is paused
            .persistentSystemOverlays(.hidden)
            .onChange(of: self.scene) { oldValue, newValue in
                switch newValue {
                case .active:
                    WindowController.shared.refPlaybackWindow(with: self.streamableVideo.id())
                    NotificationCenter.default.post(name: .twitchMuteAll, object: nil, userInfo: nil)
                case .inactive, .background:
                    if WindowController.shared.derefPlaybackWindow(with: self.streamableVideo.id()) && !WindowController.shared.mainWindowSpawned {
                        // Closed window, reopen main
                        openWindow(value: "main")
                    }
                @unknown default:
                    break
                }
            }
            .onChange(of: self.player.muted, { _, newValue in
                WindowController.shared.setPlaybackMuted(with: self.streamableVideo.id(), muted: newValue)
            })
            .onReceive(WindowController.shared.allMuteSubject, perform: { allMuted in
                guard self.delayLoading else {
                    return
                }

                print("Delaying loading")

                if allMuted {
                    // We're muted and can safely start playback
                    print("Unmuting")
                    self.delayLoading = false
                }
            })
            .onReceive(NotificationCenter.default.publisher(for: .twitchLogOut), perform: { _ in
                dismissWindow()
            })
    }
}

struct TwitchStreamVideoView: View {
    let stream: Twitch.Stream?

    var body: some View {
        if let stream = self.stream {
            TwitchWindowView(streamableVideo: .stream(stream))
        } else {
            Text("No channel specified")
        }
    }
}

struct TwitchVoDVideoView: View {
    let video: Twitch.Video?

    var body: some View {
        if let video = self.video {
            TwitchWindowView(streamableVideo: .video(video))
        } else {
            Text("No video specified")
        }
    }
}

#Preview {
    TwitchWindowView(streamableVideo: .stream(STREAM_MOCK()))
}
