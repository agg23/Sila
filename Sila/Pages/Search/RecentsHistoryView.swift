import SwiftUI
import Twitch

private let recentsHorizontalPadding: CGFloat = 16

struct RecentsHistoryView: View {
    let onSelectSearchQuery: (String) -> Void
    
    var body: some View {
        let recentsStore = RecentsStore.shared
        let noQueryView = EmptyContentView(title: "Enter a search query", systemImage: Icon.search, description: "Enter a search query to find live channels or categories.", buttonTitle: "", buttonSystemImage: "", ignoreSafeArea: false, action: nil)
        
        if recentsStore.searchRecents.isEmpty && recentsStore.recentChannels.isEmpty {
            noQueryView
        } else {
            RecentChannelsSection(onSelectSearchQuery: self.onSelectSearchQuery)
                .padding(.vertical, 16)
        }
    }
}

private struct RecentChannelsSection: View {
    @Environment(AuthController.self) private var authController

    @ObservedObject private var recentsStore = RecentsStore.shared
    @State private var loader = StandardDataLoader<[String: ChannelStatus]>()

    @State private var channelStatuses: [String: ChannelStatus] = [:]

    let onSelectSearchQuery: (String) -> Void

    var body: some View {
        List {
            if !self.recentsStore.searchRecents.isEmpty {
                Section(content: {
                    ForEach(self.recentsStore.searchRecents, id: \.self) { query in
                        Button {
                            self.onSelectSearchQuery(query)
                        } label: {
                            HStack {
                                Image(systemName: Icon.search)
                                    .foregroundColor(.secondary)
                                Text(query)
                                    .lineLimit(1)
                                Spacer()
                            }
                        }
                    }
                }, header: {
                    RecentsSectionHeader(title: "Search History") {
                        self.recentsStore.clearSearchRecents()
                    }
                })
                .listRowSpacing(8)
            }

            if !self.recentsStore.recentChannels.isEmpty {
                Section(content: {
                    ForEach(self.recentsStore.recentChannels) { recentChannel in
                        RecentChannelRow(
                            recentChannel: recentChannel,
                            channelStatus: self.channelStatuses[recentChannel.userLogin] ?? .unknown
                        )
                    }
                }, header: {
                    RecentsSectionHeader(title: "Recently Opened Channels") {
                        self.recentsStore.clearRecentChannels()
                    }
                })
            }
        }
        .scrollContentBackground(.hidden)
        .listStyle(.plain)
        .task {
            guard let api = self.authController.status.api() else {
                return
            }

            let userLogins = self.recentsStore.recentChannels.map { $0.userLogin }
            let userLoginsWithoutImages = self.recentsStore.recentChannels.filter { $0.profileImageUrl == nil }.map { $0.userLogin }
            async let streams = try? await api.helix(endpoint: .getStreams(userLogins: userLogins))
            async let users = !userLoginsWithoutImages.isEmpty ? try? await api.helix(endpoint: .getUsers(ids: [], names: userLoginsWithoutImages)) : nil

            if let (streams, _) = await streams {
                var statuses: [String: ChannelStatus] = [:]
                for login in userLogins {
                    if let stream = streams.first(where: { $0.userLogin == login }) {
                        statuses[login] = .online(stream)
                    } else {
                        statuses[login] = .offline
                    }
                }

                self.channelStatuses = statuses
            }

            if let users = await users {
                for user in users {
                    self.recentsStore.addRecentChannel(profileImageUrl: user.profileImageUrl, for: user.login)
                }
            }
        }
    }
}

private struct RecentsSectionHeader: View {
    let title: String
    let onClear: () -> Void
    
    var body: some View {
        HStack {
            Text(self.title)
            Spacer()
            Button("Clear") {
                self.onClear()
            }
            .buttonStyle(.borderless)
        }
        .frame(height: 32)
    }
}

private struct RecentChannelRow: View {
    @Environment(\.openWindow) private var openWindow
    
    let recentChannel: RecentChannel
    let channelStatus: ChannelStatus
    
    var isEnabled: Bool {
        if case .online = self.channelStatus {
            return true
        }
        return false
    }
    
    var body: some View {
        Button {
            if case .online(let stream) = self.channelStatus {
                StreamOpener.openStream(stream: stream, openWindow: self.openWindow, profileImageUrl: self.recentChannel.profileImageUrl)
            }
        } label: {
            HStack {
                ProfileImage(imageUrl: self.recentChannel.profileImageUrl != nil ? URL(string: self.recentChannel.profileImageUrl!) : nil)
                    .frame(width: 40, height: 40)
                    .opacity(!self.isEnabled ? 0.5 : 1.0)

                VStack(alignment: .leading, spacing: 2) {
                    Text(self.recentChannel.userName)
                        .lineLimit(1)

                    Group {
                        switch self.channelStatus {
                        case .online(let stream):
                            Text(stream.gameName)
                        case .offline:
                            Text("Offline")
                        case .unknown:
                            Text("Loading...")
                        }
                    }
                    .font(.caption)
                }
                
                Spacer()
            }
        }
        .disabled(!self.isEnabled)
    }
}

enum ChannelStatus {
    case unknown
    case online(Twitch.Stream)
    case offline
}

struct StreamOpener {
    static func openStream(stream: Twitch.Stream, openWindow: OpenWindowAction, profileImageUrl: String?) {
        openWindow(id: Window.stream, value: stream)
        
        RecentsStore.shared.addRecentChannel(
            userLogin: stream.userLogin,
            userName: stream.userName,
            profileImageUrl: profileImageUrl
        )
    }
}
