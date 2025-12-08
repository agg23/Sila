//
//  StreamListConfigurationIntent.swift
//  WidgetsExtension
//
//  Created by Adam Gastineau on 12/6/25.
//

import WidgetKit
import AppIntents
import Twitch

struct ChannelPosterConfigurationIntent: WidgetConfigurationIntent, Copyable {
    static var title: LocalizedStringResource { "Channel Poster" }
    static var description: IntentDescription? { "Displays a poster for a Twitch channel" }

    @Parameter(title: "Channel")
    var selectedChannel: ChannelOption?

    @Parameter(title: "Show Channel Name", default: true)
    var displayChannelName: Bool
}
