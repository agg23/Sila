//
//  RecentsHistoryView.swift
//  Sila
//
//  Created for issue #42
//

import SwiftUI
import Twitch

private let recentsHorizontalPadding: CGFloat = 16

struct RecentsHistoryView: View {
    let onSelectSearchQuery: (String) -> Void
    
    var body: some View {
        let recentsStore = RecentsStore.shared
        let noQueryView = EmptyContentView(title: "Enter a search query", systemImage: Icon.search, description: "Enter a search query to find live channels or categories.", buttonTitle: "", buttonSystemImage: "", ignoreSafeArea: false, action: nil)
        
        if recentsStore.searchRecents.isEmpty && recentsStore.recentStreams.isEmpty {
            noQueryView
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    SearchRecentsSection(onSelectSearchQuery: self.onSelectSearchQuery)
                    RecentStreamsSection()
                }
                .padding(.vertical, 16)
            }
        }
    }
}

private struct SearchRecentsSection: View {
    @ObservedObject private var recentsStore = RecentsStore.shared
    let onSelectSearchQuery: (String) -> Void
    
    var body: some View {
        if !recentsStore.searchRecents.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                RecentsSectionHeader(title: "Search History") {
                    recentsStore.clearSearchRecents()
                }
                
                List {
                    ForEach(recentsStore.searchRecents, id: \.self) { query in
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
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .frame(height: CGFloat(recentsStore.searchRecents.count) * 44)
            }
        }
    }
}

private struct RecentStreamsSection: View {
    @ObservedObject private var recentsStore = RecentsStore.shared
    @State private var loader = StandardDataLoader<[String: StreamStatus]>()
    
    var body: some View {
        if !recentsStore.recentStreams.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                RecentsSectionHeader(title: "Recently Opened Streams") {
                    recentsStore.clearRecentStreams()
                }
                
                StandardDataView(loader: self.$loader) { api, _ in
                    let userLogins = recentsStore.recentStreams.map { $0.userLogin }
                    let (streams, _) = try await api.getStreams(userLogins: userLogins)
                    
                    var statuses: [String: StreamStatus] = [:]
                    for login in userLogins {
                        if let stream = streams.first(where: { $0.userLogin == login }) {
                            statuses[login] = .online(stream)
                        } else {
                            statuses[login] = .offline
                        }
                    }
                    return statuses
                } content: { streamStatuses in
                    List {
                        ForEach(recentsStore.recentStreams) { recentStream in
                            RecentStreamRow(
                                recentStream: recentStream,
                                streamStatus: streamStatuses[recentStream.userLogin] ?? .unknown
                            )
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .frame(height: CGFloat(recentsStore.recentStreams.count) * 64)
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
                .font(.title2)
                .bold()
            Spacer()
            Button("Clear") {
                self.onClear()
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, recentsHorizontalPadding)
    }
}

private struct RecentStreamRow: View {
    @Environment(\.openWindow) private var openWindow
    
    let recentStream: RecentStream
    let streamStatus: StreamStatus
    
    var isEnabled: Bool {
        if case .online = self.streamStatus {
            return true
        }
        return false
    }
    
    var body: some View {
        Button {
            if case .online(let stream) = self.streamStatus {
                StreamOpener.openStream(stream: stream, openWindow: self.openWindow, addToRecents: false)
            }
        } label: {
            HStack {
                ZStack {
                    Color.gray.opacity(0.3)
                    Image(systemName: Icon.channel)
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .frame(width: 40, height: 40)
                .clipShape(.rect(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(self.recentStream.userName)
                        .lineLimit(1)
                    
                    switch self.streamStatus {
                    case .online(let stream):
                        Text(stream.gameName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    case .offline:
                        Text("Offline")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    case .unknown:
                        Text("Loading...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
        }
        .disabled(!self.isEnabled)
        .buttonStyle(.plain)
    }
}

enum StreamStatus {
    case unknown
    case online(Twitch.Stream)
    case offline
}

struct StreamOpener {
    static func openStream(stream: Twitch.Stream, openWindow: OpenWindowAction, addToRecents: Bool = true) {
        if addToRecents {
            RecentsStore.shared.addRecentStream(stream, resort: true)
        }
        openWindow(id: Window.stream, value: stream)
    }
}
