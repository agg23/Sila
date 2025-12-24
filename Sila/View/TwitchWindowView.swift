//
//  TwitchWindowView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/18/24.
//

import SwiftUI
import Twitch

struct TwitchWindowView: View {
    @AppStorage(Setting.smallBorderRadius) var smallBorderRadius: Bool = false

    @State private var presentableController: PlaybackPresentableController? = nil
    @State private var controlVisibility = Visibility.visible

    let streamableVideo: StreamableVideo

    var contentId: String {
        PlaybackPresentableController.contentId(for: self.streamableVideo)
    }

    var body: some View {
        VStack {
            if let presentableController = self.presentableController {
                TwitchContentView(controlVisibility: self.$controlVisibility, player: presentableController.model, streamableVideo: self.streamableVideo, isStandaloneWindow: true)
            }
        }
        .presentableTracking(contentId: self.contentId, role: .standalone, factory: {
            PlaybackPresentableController(contentId: self.contentId, model: WebViewPlayer())
        }, withController: { controller in
            self.presentableController = controller
        })
        .roundedBackground(.glass)
    }
}

struct TwitchContentView: View {
    @AppStorage(Setting.dimSurroundings) var dimSurroundings: Bool = false

    @Environment(\.scenePhase) private var scene
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.dismiss) private var dismissNavView

    // TODO: Implement
//    @State private var delayLoading = !WindowController.shared.checkAllMuted()
    @State private var delayLoading = false
    @State private var delayTimer: Timer?
    @Binding var controlVisibility: Visibility

//    let presentableController: PlaybackPresentableController
    let player: WebViewPlayer
    let streamableVideo: StreamableVideo
    let isStandaloneWindow: Bool

    var contentId: String {
        PlaybackPresentableController.contentId(for: self.streamableVideo)
    }

    var body: some View {
        TwitchVideoView(controlVisibility: self.$controlVisibility, streamableVideo: self.streamableVideo, delayLoading: self.delayLoading, player: self.player)
            // Set aspect ratio and enforce uniform resizing
            // This is on an inner view to prevent breaking .persistentSystemOverlays() modification
            // TODO: Do something about this on embedded views
//            .windowGeometryPreferences(minimumSize: CGSize(width: 160.0 * 4, height: 90.0 * 4), resizingRestrictions: .uniform)
            .preferredSurroundingsEffect(self.dimSurroundings ? .systemDark : nil)
            // Controlling with the ornament overlay keeps the grabber completely in sync
            .persistentSystemOverlays(self.controlVisibility)
            // TODO: Rewrite after windowing changes
//            .onChange(of: self.presentableController, { _, _ in
//                // When we gain a PresentableController, set up system and send mute
//                print("Setting onMute")
//                self.presentableController.onMute = {
//                    print("Started mute")
//                    let _ = await self.player.setMute(true)
//                    print("Mute completed")
//                }
//
//                Task {
//                    await PlaybackPresentableController.muteAll(except: self.contentId)
//                }
//            })
            .onAppear {
                if self.delayLoading {
                    self.delayTimer?.invalidate()
                    self.delayTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: { _ in
                        // If time has passed and we didn't allow loading, something probably went wrong
                        // Make sure we don't freeze here
                        print("Delay loading timed out. Starting page load")
                        self.delayLoading = false
                    })
                }

                if case .video(_) = self.streamableVideo {
                    self.player.setIsVideo(true)
                } else {
                    self.player.setIsVideo(false)
                }
            }
            // TODO: Rewrite after windowing changes
//            .onDisappear {
//                print("Clearing onMute")
//                self.presentableController?.onMute = nil
//            }
//            .onChange(of: self.player.muted, { _, newValue in
//                if let controller = self.presentableController {
//                    controller.isMuted = newValue
//                }
//            })
            .onReceive(NotificationCenter.default.publisher(for: .twitchLogOut), perform: { _ in
                if self.isStandaloneWindow {
                    self.dismissWindow()
                } else {
                    self.dismissNavView()
                }
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
