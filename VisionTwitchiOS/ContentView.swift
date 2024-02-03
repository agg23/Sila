//
//  ContentView.swift
//  VisionTwitchiOS
//
//  Created by Adam Gastineau on 2/2/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Hello, world!")
            TwitchVideoView()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
