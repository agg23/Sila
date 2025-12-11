//
//  ChannelWidgetConfiguration.swift
//  WidgetsExtension
//
//  Created by Adam Gastineau on 12/10/25.
//

import WidgetKit
import SwiftUI
import AppIntents

struct ChannelWidgetConfiguration<T: ChannelConfigurationIntent>: WidgetConfiguration {
    let kind: String
    let intentType: T.Type
    let supportedFamilies: [WidgetFamily]

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: self.kind, intent: self.intentType, provider: ChannelTimelineProvider()) { entry in
            SingleChannelView(entry: entry)
        }
        .configurationDisplayName(T.title)
        .description(T.description?.descriptionText ?? "")
        .supportedFamilies(self.supportedFamilies)
        // The image has glare without using .paper
        .widgetTexture(.paper)
        .contentMarginsDisabled()
    }
}
