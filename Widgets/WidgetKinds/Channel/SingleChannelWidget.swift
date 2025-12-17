//
//  SingleChannelWidget.swift
//  WidgetsExtension
//
//  Created by Adam Gastineau on 12/10/25.
//

import WidgetKit
import SwiftUI
import Twitch
import UIImageColors
import os.log
import AppIntents

struct SingleChannelWidget: Widget {
    var body: some WidgetConfiguration {
        ChannelWidgetConfiguration(
            kind: "SingleChannelWidget",
            intentType: SingleChannelConfigurationIntent.self,
            // Small square, ~2:1 short/wide rectange, and large square
            supportedFamilies: [.systemSmall, .systemMedium, .systemLarge]
        )
    }
}
