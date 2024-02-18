//
//  StreamGridPageView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/18/24.
//

import SwiftUI
import Twitch

struct StreamGridPageView: View {
    let streams: [Twitch.Stream]

    var body: some View {
        ScrollView {
            StreamGridView(streams: self.streams)
                .padding(.all, 32)
        }
    }
}

#Preview {
    StreamGridPageView(streams: STREAMS_LIST_MOCK())
}
