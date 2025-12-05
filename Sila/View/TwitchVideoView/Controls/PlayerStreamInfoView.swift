//
//  StreamStatusControlView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/25/24.
//

import SwiftUI
import Twitch

struct PlayerStreamInfoView: View {
    @State private var loader = StandardDataLoader<User?>()
    @State private var refreshTask: Task<(), Never>?

    let player: WebViewPlayer
    let streamableVideo: StreamableVideo

    var body: some View {
        DataView(loader: self.$loader, task: { api, _ in
            let users = try await api.helix(endpoint: .getUsers(ids: [self.streamableVideo.userId]))
            return users.first
        }, content: { user, _ in
            PlayerStreamInfoContentWrapperView(streamableVideo: self.streamableVideo, user: user)
        }, loading: { user in
            PlayerStreamInfoContentWrapperView(streamableVideo: self.streamableVideo, user: user as? User)
        }, error: { (_: Error?) in
            PlayerStreamInfoContentWrapperView(streamableVideo: self.streamableVideo, user: nil)
        })
        .padding(6)
        .frame(width: 600, height: 80)
        .insetBackground()
        // 8 inner radius + 6 padding
        .clipShape(.rect(cornerRadius: 14))
        .onChange(of: self.player.channelId, { oldValue, newValue in
            guard oldValue != nil, let newValue = newValue else {
                // If we're changing from (or to) an empty value, ignore it
                return
            }

            self.requestState(channelId: newValue)
        })
    }

    private func requestState(channelId: String) {
        self.refreshTask?.cancel()

        self.refreshTask = Task {
            await self.loader.requestMore { _, apiAndUser in
                let users = try await apiAndUser.0.helix(endpoint: .getUsers(ids: [channelId]))
                return users.first
            }

            self.refreshTask = nil
        }
    }
}

struct PlayerStreamInfoContentWrapperView: View {
    let streamableVideo: StreamableVideo
    let user: User?

    var body: some View {
        switch self.streamableVideo {
        case .stream(let stream):
            PlayerStreamInfoContentView(title: stream.title, userName: stream.userName, gameName: stream.gameName, profileImageUrl: self.profileImageUrl(), viewerCount: stream.viewerCount, timestamp: stream.startedAt)
        case .video(let video):
            PlayerStreamInfoContentView(title: video.title, userName: video.userName, gameName: nil, profileImageUrl: self.profileImageUrl(), viewerCount: nil, timestamp: nil)
        }
    }

    func profileImageUrl() -> URL? {
        if let user = self.user {
            return URL(string: user.profileImageUrl)
        }

        return nil
    }
}

struct PlayerStreamInfoContentView: View {
    let title: String
    let userName: String
    let gameName: String?
    let profileImageUrl: URL?
    let viewerCount: Int?
    let timestamp: Date?

    var body: some View {
        let title = !self.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? self.title : self.userName

        HStack(alignment: .top) {
            ProfileImage(imageUrl: self.profileImageUrl)
            VStack(alignment: .leading) {
                Text(title)
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
            VStack(alignment: .trailing) {
                if let timestamp = self.timestamp {
                    RuntimeTimelineView(timestamp: timestamp)
                        .monospacedDigit()
                        .multilineTextAlignment(.trailing)
                }

                Spacer()

                if let viewerCount = self.viewerCount {
                    ViewerCountView(viewerCount: viewerCount)
                }
            }
            .padding(.trailing, 8)
        }
    }
}

#Preview {
    PlayerStreamInfoView(player: WebViewPlayer(), streamableVideo: .stream(STREAM_MOCK()))
}

#Preview {
    PlayerStreamInfoView(player: WebViewPlayer(), streamableVideo: .video(VIDEO_MOCK()))
}
