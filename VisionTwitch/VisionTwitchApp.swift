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

    var body: some Scene {
        WindowGroup {
            ContentView()
//                .onAppear {
//                    openWindow(id: "chat")
//                }
        }

//        WindowGroup(id: "chat") {
//            ChatWebView()
//        }
//            .defaultSize(width: 300, height: 500)

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }.immersionStyle(selection: .constant(.progressive), in: .progressive)
    }
}
