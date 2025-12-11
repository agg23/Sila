//
//  ChannelPosterWidget.swift
//  WidgetsExtension
//
//  Created by Adam Gastineau on 12/6/25.
//

import WidgetKit
import SwiftUI
import Twitch
import UIImageColors
import os.log
import AppIntents

struct ChannelPosterWidget: Widget {
    var body: some WidgetConfiguration {
        ChannelWidgetConfiguration(kind: "ChannelPosterWidget", intentType: ChannelPosterConfigurationIntent.self, supportedFamilies: [.systemExtraLargePortrait])
    }
}
