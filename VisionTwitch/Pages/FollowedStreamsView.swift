//
//  FollowedStreamsView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/17/24.
//

import SwiftUI

struct FollowedStreamsView: View {
    var body: some View {
        PickerTabView(leftTitle: "Live", leftView: {
            self.liveStreams
        }, rightTitle: "All Channels") {
            Text("All Channels")
        }
    }

    @ViewBuilder
    var liveStreams: some View {
        DataView(taskClosure: { api in
            return Task {
                let (streams, _) = try await api.getFollowedStreams()
                return streams
            }
        }, content: { streams in
            ScrollGridView {
                StreamGridView(streams: streams)
            }
        }, error: { _ in
            Text("Error")
        }, requiresAuth: true, runOnAppear: true)
    }
}
