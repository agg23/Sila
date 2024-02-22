//
//  VisionTwitchApp.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/2/24.
//

import SwiftUI

@main
struct VisionTwitchApp: App {
    @Environment(\.openWindow) private var openWindow

    @State var authController = AuthController()

    var body: some Scene {
        WindowGroup {
            MainWindowView()
        }
        .environment(\.authController, self.authController)

        WindowGroup(id: "channelVideo", for: String.self) { channel in
            if let channel = channel.wrappedValue {
                TwitchWindowView(channel: channel)
            } else {
                Text("No channel specified")
            }
        }
        .environment(\.authController, self.authController)
        .defaultSize(CGSize(width: 800.0, height: 450.0))

//        WindowGroup(id: "chat") {
//            ChatWebView()
//        }
//        .defaultSize(width: 300, height: 500)
    }
}
