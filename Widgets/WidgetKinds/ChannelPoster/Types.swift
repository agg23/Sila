//
//  Types.swift
//  WidgetsExtension
//
//  Created by Adam Gastineau on 12/7/25.
//

import UIKit
import UIImageColors
import WidgetKit

struct ChannelPosterTimelineEntry: TimelineEntry {
    let date: Date

    let state: State

    let intent: ChannelPosterConfigurationIntent
    let context: TimelineProviderContext

    enum State {
        case data(ChannelPosterData)
        case noData(displayName: String)
        case unconfigured(isPreview: Bool)
    }

    struct ChannelPosterData {
        var displayName: String
        var profileImage: ProfileImage

        var status: Status

        enum Status {
            case online(_ gameName: String, startedAt: Date, viewerCount: Int)
            case offline
        }
    }
}

struct ProfileImage {
    let image: UIImage
    let colors: UIImageColors

    let didFetch: Bool

    static let unfetched = ProfileImage(image: UIImage(imageLiteralResourceName: "SilaDummyProfileImage"), colors: UIImageColors.defaultColors, didFetch: false)

    init(image: UIImage, colors: UIImageColors) {
        self.init(image: image, colors: colors, didFetch: true)
    }

    private init(image: UIImage, colors: UIImageColors, didFetch: Bool) {
        self.image = image
        self.colors = colors
        self.didFetch = didFetch
    }
}
