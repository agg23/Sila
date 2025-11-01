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
    let channel: Twitch.User

    var body: some View {
        SharedStreamButtonView(source: .video(self.video), displayUrl: self.video.thumbnailUrl, profileImageUrl: self.channel.profileImageUrl, preTitleLeft: "", title: self.video.title, subtitle: self.video.userName)
    }
}

#Preview {
    VODButtonView(video: VIDEO_MOCK(), channel: USER_MOCK())
}
