//
//  AssetSelectionView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/8/24.
//

import SwiftUI

struct AssetSelectionView: View {
    @Environment(\.openWindow) private var openWindow

    @State var enteredText: String = ""

    var body: some View {
        HStack {
            VStack {
                FixedChannelLaunchButton(channelName: "BarbarousKing")
                FixedChannelLaunchButton(channelName: "Patty")
                FixedChannelLaunchButton(channelName: "GrandPooBear")
                FixedChannelLaunchButton(channelName: "Kitboga")
                FixedChannelLaunchButton(channelName: "Oatsngoats")
                FixedChannelLaunchButton(channelName: "GamesDoneQuick")
            }
            VStack {
                TextField(text: $enteredText) {
                    Text("Channel:")
                }
                Button {
                    openWindow(id: "channelVideo", value: self.enteredText)
                } label: {
                    Text("Open Channel")
                }

            }
        }
    }
}

struct FixedChannelLaunchButton: View {
    @Environment(\.openWindow) private var openWindow

    var channelName: String

    var body: some View {
        Button {
            openWindow(id: "channelVideo", value: channelName)
        } label: {
            Text(channelName)
        }
    }
}

#Preview {
    AssetSelectionView()
}
