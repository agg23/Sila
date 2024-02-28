//
//  VODButtonView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/27/24.
//

import SwiftUI
import Twitch

struct VODButtonView: View {
    let video: Video

    var body: some View {
        SharedStreamButtonView(source: .video(self.video), displayUrl: self.video.thumbnailUrl, preTitleLeft: "", preTitleRight: "", title: self.video.title, subtitle: self.video.userName)
    }
}

#Preview {
    VODButtonView(video: VIDEO_MOCK())
}
