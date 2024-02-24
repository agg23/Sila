//
//  ChannelButtonView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/19/24.
//

import SwiftUI
import Twitch

struct ChannelButtonView: View {
    @Environment(Router.self) private var router

    let channel: Twitch.User

    var body: some View {
        AsyncImageButtonView(imageUrl: URL(string: self.channel.profileImageUrl), aspectRatio: 1.0) {
            router.path.append(Route.channel(user: UserWrapper.user(self.channel)))
        } content: {
            VStack(alignment: .leading) {
                Text(self.channel.displayName)
                    .font(.title3)
                    .lineLimit(1, reservesSpace: true)
            }
        }
    }
}

#Preview {
    ChannelButtonView(channel: USER_MOCK())
}
