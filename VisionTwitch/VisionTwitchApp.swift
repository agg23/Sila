//
//  VisionTwitchApp.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/2/24.
//

import SwiftUI

@main
struct VisionTwitchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }.immersionStyle(selection: .constant(.progressive), in: .progressive)
    }
}
