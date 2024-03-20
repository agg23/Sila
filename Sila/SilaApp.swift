//
//  SilaApp.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/2/24.
//

import SwiftUI
import AppIntents
import Twitch

@main
struct SilaAppApp: App {
    @State var authController: AuthController
    @State var router: Router

    init() {
        let authController = AuthController()
        let router = Router()

        self.authController = authController
        self.router = router

        AppDependencyManager.shared.add(dependency: authController)
        AppDependencyManager.shared.add(dependency: router)

        Shortcuts.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup(for: String.self) { main in
            MainWindowView()
                .mainWindow()
                // This is the default window size of the launching animation
                .frame(width: 1280.0, height: 720.0)
                // For some reason we crash if we put this environment on the window
                .environment(self.router)
        } defaultValue: {
            // Set default value so there's a shared ID we can use to reuse the window
            // TODO: This doesn't work for some reason
            return "main"
        }
        .windowResizability(.contentSize)
        .environment(\.authController, self.authController)

        WindowGroup(id: "stream", for: Twitch.Stream.self) { $stream in
            TwitchStreamVideoView(stream: stream)
                .playbackWindow(for: stream)
        } defaultValue: {
            // Providing a default allows us to refocus an open window
            // TODO: Replace with actual value
            STREAM_MOCK()
        }
        .environment(\.authController, self.authController)
        .defaultSize(CGSize(width: 1280.0, height: 720.0))
        .windowStyle(.plain)

        #if VOD_ENABLED
        WindowGroup(id: "vod", for: Twitch.Video.self) { $video in
            TwitchVoDVideoView(video: video)
        }
        .environment(\.authController, self.authController)
        .defaultSize(CGSize(width: 1280.0, height: 720.0))
        #endif
    }
}
