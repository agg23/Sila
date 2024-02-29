//
//  StreamStatusControlView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/25/24.
//

import SwiftUI
import Twitch

struct StreamableVideoStatusControlView: View {
    @State private var loader = StandardDataLoader<User?>()

    let streamableVideo: StreamableVideo

    var body: some View {
        DataView(loader: self.$loader, task: { api, _ in
            let users = try await api.getUsers(userIDs: [self.userId()])

            guard !users.isEmpty else {
                return nil
            }

            return users[0]
        }, content: { user in
            StreamableVideoStatusControlContentView(streamableVideo: self.streamableVideo, user: user)
        }, loading: { user in
            StreamableVideoStatusControlContentView(streamableVideo: self.streamableVideo, user: user ?? nil)
        }, error: { (_: HelixError?) in
            StreamableVideoStatusControlContentView(streamableVideo: self.streamableVideo, user: nil)
        })
        .padding()
        .frame(width: 600, height: 100)
        .insetBackground()
        .clipShape(.rect(cornerRadius: 20))
    }

    func userId() -> String {
        switch self.streamableVideo {
        case .stream(let stream):
            return stream.userId
        case .video(let video):
            return video.userId
        }
    }
}

struct StreamableVideoStatusControlContentView: View {
    let streamableVideo: StreamableVideo
    let user: User?

    var body: some View {
        switch self.streamableVideo {
        case .stream(let stream):
            StreamableVideoStatusDisplayView(title: stream.title, userName: stream.userName, gameName: stream.gameName, profileImageUrl: self.profileImageUrl(), viewerCount: stream.viewerCount)
        case .video(let video):
            StreamableVideoStatusDisplayView(title: video.title, userName: video.userName, gameName: nil, profileImageUrl: self.profileImageUrl(), viewerCount: nil)
        }
    }

    func profileImageUrl() -> URL? {
        if let user = self.user {
            return URL(string: user.profileImageUrl)
        }

        return nil
    }
}

struct StreamableVideoStatusDisplayView: View {
    let title: String
    let userName: String
    let gameName: String?
    let profileImageUrl: URL?
    let viewerCount: Int?

    var body: some View {
        HStack(alignment: .top) {
            LoadingAsyncImage(imageUrl: self.profileImageUrl, aspectRatio: 1.0)
            VStack(alignment: .leading) {
                Text(self.title)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(self.userName)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(self.gameName ?? "")
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if let viewerCount = viewerCount {
                Image(systemName: Icon.viewerCount)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.red, .white)
                Text(viewerCount.formatted(.number))
            }
        }
    }
}

#Preview {
    StreamableVideoStatusControlView(streamableVideo: .stream(STREAM_MOCK()))
}

#Preview {
    StreamableVideoStatusControlView(streamableVideo: .video(VIDEO_MOCK()))
}
