//
//  ContentView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/2/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    var body: some View {
        VStack {
            TwitchVideoView()
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
