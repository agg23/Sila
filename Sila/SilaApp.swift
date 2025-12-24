//
//  SilaApp.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/2/24.
//

import SwiftUI
import AppIntents
import Twitch
import Nuke

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

        // Make sure our thumbnails expire from the memory Nuke cache
        ImageCache.shared.ttl = 120

        Task {
            await EmoteController.shared.fetchGlobalEmotes()
        }
    }

    var body: some Scene {
        WindowGroup(for: String.self) { $id in
            MainWindowView()
                // This is the default window size of the launching animation
                .frame(width: 1280.0, height: 720.0)
                // For some reason we crash if we put this environment on the window
                .environment(self.router)
                .environment(self.authController)
        } defaultValue: {
            // Set default value so there's a shared ID we can use to reuse the window
            // TODO: This doesn't work for some reason
            return "main"
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)

        WindowGroup(id: Window.stream, for: Twitch.Stream.self) { $stream in
            TwitchStreamVideoView(stream: stream)
                .environment(self.authController)
                // Prevent reopening the app from spawning this window
                // Closing the main window, then closing all video windows will open the main
                // window when the app is launched again
                .handlesExternalEvents(preferring: [], allowing: [])
        } defaultValue: {
            // Providing a default allows us to refocus an open window
            // TODO: Replace with actual value
            STREAM_MOCK()
        }
        .defaultSize(CGSize(width: 1280.0, height: 720.0))
        .windowStyle(.plain)
        .defaultLaunchBehavior(.suppressed)

        #if VOD_ENABLED
        WindowGroup(id: Window.vod, for: Twitch.Video.self) { $video in
            TwitchVoDVideoView(video: video)
                .environment(self.authController)
        }
        .defaultSize(CGSize(width: 1280.0, height: 720.0))
        .windowStyle(.plain)
        .defaultLaunchBehavior(.suppressed)
        #endif

        WindowGroup(id: Window.chat, for: ChatWindowModel.self) { $chat in
            ChatPaneWindow(channelName: chat.channelName, userId: chat.userId, title: chat.title)
        } defaultValue: {
            let defaultUser = USER_MOCK()
            return ChatWindowModel(channelName: defaultUser.login, userId: defaultUser.id, title: defaultUser.displayName)
        }
        .defaultSize(CGSize(width: 400.0, height: 720.0))
        .defaultLaunchBehavior(.suppressed)

        ImmersiveSpace(id: Window.followerStream, for: StreamableVideo.self) { $streamableVideo in
            FollowerImmersiveView(streamableVideo: $streamableVideo.wrappedValue)
                .environment(self.authController)
        } defaultValue: {
            // TODO: Replace with actual value
            .stream(STREAM_MOCK())
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
