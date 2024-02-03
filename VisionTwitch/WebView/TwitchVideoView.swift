//
//  TwitchVideoView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/2/24.
//

import SwiftUI
import WebKit
import Swifter

struct TwitchVideoView: View {
    let twitch = WebView()

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        WebView()
        Button(action: {
            self.twitch.reload()
        }, label: {
            /*@START_MENU_TOKEN@*/Text("Button")/*@END_MENU_TOKEN@*/
        })

    }
}

#Preview {
    TwitchVideoView()
}
