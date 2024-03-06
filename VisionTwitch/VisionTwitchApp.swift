//
//  VisionTwitchApp.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/2/24.
//

import SwiftUI
import Twitch
import VisionPane
import TwitchIRC

@main
struct VisionTwitchApp: App {
    @Environment(\.openWindow) private var openWindow

    @State var authController = AuthController()

    var body: some Scene {
        WindowGroup(for: String.self) { main in
            MainWindowView()
                .frame(width: 1400, height: 800)
        } defaultValue: {
            // Set default value so there's a shared ID we can use to reuse the window
            // TODO: This doesn't work for some reason
            return "main"
        }
        .windowResizability(.contentSize)
        .environment(\.authController, self.authController)

        WindowGroup.Pane(id: "stream", for: Twitch.Stream.self) { stream in
            if let stream = stream.wrappedValue {
                TwitchWindowView(streamableVideo: .stream(stream))
            } else {
                Text("No channel specified")
            }
        }
        .environment(\.authController, self.authController)
        .defaultSize(CGSize(width: 1280.0, height: 720.0))

        #if VOD_ENABLED
        WindowGroup(id: "vod", for: Twitch.Video.self) { video in
            if let video = video.wrappedValue {
                TwitchWindowView(streamableVideo: .video(video))
            } else {
                Text("No video specified")
            }
        }
        .environment(\.authController, self.authController)
        .defaultSize(CGSize(width: 1280.0, height: 720.0))
        #endif
    }
}
