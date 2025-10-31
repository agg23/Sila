//
//  RecentStreamsView.swift
//  Sila
//
//  Created for issue #42
//

import SwiftUI
import Twitch

struct RecentStreamsView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(AuthController.self) private var authController
    
    @ObservedObject private var recentsStore = RecentsStore.shared
    @State private var streamStatuses: [String: StreamStatus] = [:]
    
    var body: some View {
        if !recentsStore.recentStreams.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Recently Opened Streams")
                        .font(.title2)
                        .bold()
                    Spacer()
                    Button("Clear") {
                        recentsStore.clearRecentStreams()
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.horizontal, 16)
                
                VStack(spacing: 8) {
                    ForEach(recentsStore.recentStreams) { recentStream in
                        RecentStreamButton(
                            recentStream: recentStream,
                            streamStatus: self.streamStatuses[recentStream.userLogin] ?? .unknown,
                            onTap: {
                                Task {
                                    guard let api = self.authController.status.api() else {
                                        return
                                    }
                                    
                                    let (streams, _) = try await api.getStreams(userLogins: [recentStream.userLogin])
                                    
                                    if let stream = streams.first {
                                        recentsStore.addRecentStream(stream, resort: false)
                                        self.openWindow(id: Window.stream, value: stream)
                                    }
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
            .task {
                await self.fetchStreamStatuses(for: recentsStore.recentStreams)
            }
        }
    }
    
    private func fetchStreamStatuses(for recentStreams: [RecentStream]) async {
        guard let api = self.authController.status.api() else {
            return
        }
        
        let userLogins = recentStreams.map { $0.userLogin }
        
        do {
            let (streams, _) = try await api.getStreams(userLogins: userLogins)
            
            var statuses: [String: StreamStatus] = [:]
            for login in userLogins {
                if let stream = streams.first(where: { $0.userLogin == login }) {
                    statuses[login] = .online(stream)
                } else {
                    statuses[login] = .offline
                }
            }
            
            DispatchQueue.main.async {
                self.streamStatuses = statuses
            }
        } catch {
            print("Failed to fetch stream statuses: \(error)")
        }
    }
}

enum StreamStatus {
    case unknown
    case online(Twitch.Stream)
    case offline
}

private struct RecentStreamButton: View {
    let recentStream: RecentStream
    let streamStatus: StreamStatus
    let onTap: () -> Void
    
    var isEnabled: Bool {
        if case .online = self.streamStatus {
            return true
        }
        return false
    }
    
    var body: some View {
        Button {
            self.onTap()
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
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.red)
                                .frame(width: 6, height: 6)
                            Text(stream.gameName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
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
            .padding(12)
            .background(.tertiary)
            .cornerRadius(10)
        }
        .disabled(!self.isEnabled)
        .buttonStyle(.plain)
        .buttonBorderShape(.roundedRectangle(radius: 10))
    }
}
