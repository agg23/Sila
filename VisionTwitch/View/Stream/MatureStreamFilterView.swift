//
//  MatureStreamFilterView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 3/10/24.
//

import SwiftUI
import Twitch

struct MatureStreamFilterView<Content: View>: View {
    @AppStorage(Setting.hideMature) private var hideMature: Bool = false
    @State private var filteredStreams: [Twitch.Stream] = []

    let streams: [Twitch.Stream]

    @ViewBuilder let content: ([Twitch.Stream]) -> Content

    var body: some View {
        self.content(self.filteredStreams)
            .onChange(of: self.hideMature) { _, newValue in
                self.updateFilter(hideMature: newValue)
            }
            .onChange(of: self.streams) { _, _ in
                self.updateFilter(hideMature: self.hideMature)
            }
    }

    func updateFilter(hideMature: Bool) {
        if hideMature {
            self.filteredStreams = self.streams.filter({ !$0.isMature })
        } else {
            self.filteredStreams = self.streams
        }
    }
}
