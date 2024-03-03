//
//  VisionTwitchApp.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/2/24.
//

import SwiftUI
import Twitch
import VisionPane

@main
struct VisionTwitchApp: App {
    @Environment(\.openWindow) private var openWindow

    @State var authController = AuthController()

    var body: some Scene {
        WindowGroup {
            MainWindowView()
        }
        .environment(\.authController, self.authController)

        WindowGroup.Pane(id: "stream", for: Twitch.Stream.self) { stream in
            if let stream = stream.wrappedValue {
                TwitchWindowView(streamableVideo: .stream(stream))
            } else {
                Text("No channel specified")
            }
        }
        .environment(\.authController, self.authController)
        .defaultSize(CGSize(width: 800.0, height: 450.0))

        #if VOD_ENABLED
        WindowGroup(id: "vod", for: Twitch.Video.self) { video in
            if let video = video.wrappedValue {
                TwitchWindowView(streamableVideo: .video(video))
            } else {
                Text("No video specified")
            }
        }
        .environment(\.authController, self.authController)
        .defaultSize(CGSize(width: 800.0, height: 450.0))
        #endif
    }
}
