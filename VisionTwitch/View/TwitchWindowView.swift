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

    let streamableVideo: StreamableVideo

    var body: some View {
        TwitchVideoView(streamableVideo: self.streamableVideo)
            // Set aspect ratio and enforce uniform resizing
            .windowGeometryPreferences(minimumSize: CGSize(width: 160.0, height: 90.0), resizingRestrictions: .uniform)
            // Having the overlay hidden all of the time has the intended interaction of opening and closing
            // The only issue is the grabber is not constantly visible while the video is paused
            .persistentSystemOverlays(.hidden)
            .onAppear {
                WindowController.shared.refPlaybackWindow(with: self.streamableVideo.id())
                NotificationCenter.default.post(name: .twitchMuteAll, object: nil, userInfo: nil)
            }
            .onChange(of: self.scene) { oldValue, newValue in
                if newValue == .background {
                    if WindowController.shared.derefPlaybackWindow(with: self.streamableVideo.id()) && !WindowController.shared.mainWindowSpawned {
                        // Closed window, reopen main
                        openWindow(value: "main")
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .twitchLogOut), perform: { _ in
                dismissWindow()
            })
    }
}

#Preview {
    TwitchWindowView(streamableVideo: .stream(STREAM_MOCK()))
}
