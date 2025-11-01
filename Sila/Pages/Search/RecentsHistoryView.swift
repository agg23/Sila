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
            RecentStreamsSection(onSelectSearchQuery: self.onSelectSearchQuery)
                .padding(.vertical, 16)
        }
    }
}

private struct RecentStreamsSection: View {
    @Environment(AuthController.self) private var authController

    @ObservedObject private var recentsStore = RecentsStore.shared
    @State private var loader = StandardDataLoader<[String: StreamStatus]>()

    @State private var streamStatuses: [String: StreamStatus] = [:]

    let onSelectSearchQuery: (String) -> Void

    var body: some View {
        // TODO: I don't like this formatting at all. There's too many problems. The section headers have a straight line at the top when they intersect with the NavStack toolbar
        List {
            if !self.recentsStore.searchRecents.isEmpty {
                // TODO: Section headers don't have a gap with content, so highlighting the first item shows the sections touching
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

            if !self.recentsStore.recentStreams.isEmpty {
                Section(content: {
                    ForEach(self.recentsStore.recentStreams) { recentStream in
                        RecentStreamRow(
                            recentStream: recentStream,
                            streamStatus: self.streamStatuses[recentStream.userLogin] ?? .unknown
                        )
                    }
                }, header: {
                    RecentsSectionHeader(title: "Recently Opened Streams") {
                        self.recentsStore.clearSearchRecents()
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

            let userLogins = self.recentsStore.recentStreams.map { $0.userLogin }
            guard let (streams, _) = try? await api.getStreams(userLogins: userLogins) else {
                return
            }

            var statuses: [String: StreamStatus] = [:]
            for login in userLogins {
                if let stream = streams.first(where: { $0.userLogin == login }) {
                    statuses[login] = .online(stream)
                } else {
                    statuses[login] = .offline
                }
            }

            self.streamStatuses = statuses
        }
    }
}

private struct RecentsSectionHeader: View {
    let title: String
    let onClear: () -> Void
    
    var body: some View {
        // TODO: This has a background. I don't know how to remove it
        HStack {
            Text(self.title)
            Spacer()
            Button("Clear") {
                self.onClear()
            }
            // TODO: I don't like the styling of this button combined with the background
            .buttonStyle(.borderless)
        }
        .frame(height: 32)
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
                Image(systemName: Icon.channel)
                    .font(.title2)
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(self.recentStream.userName)
                        .lineLimit(1)

                    Group {
                        switch self.streamStatus {
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
