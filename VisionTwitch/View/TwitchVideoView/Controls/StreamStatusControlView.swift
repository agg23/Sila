//
//  StreamStatusControlView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/25/24.
//

import SwiftUI
import Twitch

struct StreamStatusControlView: View {
    @State private var loader = StandardDataLoader<User?>()

    let stream: Twitch.Stream

    var body: some View {
        DataView(loader: self.$loader, task: { api, _ in
            let users = try await api.getUsers(userIDs: [self.stream.userId])

            guard !users.isEmpty else {
                return nil
            }

            return users[0]
        }, content: { user in
            StreamStatusControlContentView(stream: self.stream, user: user)
        }, loading: { user in
            StreamStatusControlContentView(stream: self.stream, user: user ?? nil)
        }, error: { (_: HelixError?) in
            StreamStatusControlContentView(stream: self.stream, user: nil)
        })
        .padding()
        .frame(width: 600, height: 100)
        .insetBackground()
        .clipShape(.rect(cornerRadius: 20))
    }
}

struct StreamStatusControlContentView: View {
    let stream: Twitch.Stream
    let user: User?

    var body: some View {
        HStack(alignment: .top) {
            LoadingAsyncImage(imageUrl: self.profileImageUrl(), aspectRatio: 1.0)
            VStack(alignment: .leading) {
                Text(self.stream.title)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(self.stream.userName)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer()
            Image(systemName: Icon.viewerCount)
                .symbolRenderingMode(.palette)
                .foregroundStyle(.red, .white)
            Text(self.stream.viewerCount.formatted(.number))
        }
    }

    func profileImageUrl() -> URL? {
        if let user = self.user {
            return URL(string: user.profileImageUrl)
        }

        return nil
    }
}

#Preview {
    StreamStatusControlView(stream: STREAM_MOCK())
}
