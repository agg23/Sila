//
//  ChannelConfigurationIntent.swift
//  WidgetsExtension
//
//  Created by Adam Gastineau on 12/6/25.
//

import WidgetKit
import AppIntents
import Twitch

protocol ChannelConfigurationIntent: WidgetConfigurationIntent, Copyable {
    static var title: LocalizedStringResource { get }
    static var description: IntentDescription? { get }

    var selectedChannel: ChannelOption { get }
    var displayChannelName: Bool { get }
}

struct ChannelPosterConfigurationIntent: ChannelConfigurationIntent {
    static var title: LocalizedStringResource { "Channel Poster" }
    static var description: IntentDescription? { "Displays the current live status of a Twitch channel." }

    @Parameter(title: "Channel", default: .randomFollowed)
    var selectedChannel: ChannelOption

    @Parameter(title: "Show Channel Name", default: true)
    var displayChannelName: Bool
}

struct SingleChannelConfigurationIntent: ChannelConfigurationIntent {
    static var title: LocalizedStringResource { "Channel Status" }
    static var description: IntentDescription? { "Displays the current live status of a Twitch channel." }

    @Parameter(title: "Channel", default: .randomFollowed)
    var selectedChannel: ChannelOption

    @Parameter(title: "Show Channel Name", default: true)
    var displayChannelName: Bool
}
