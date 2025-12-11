//
//  Types.swift
//  WidgetsExtension
//
//  Created by Adam Gastineau on 12/7/25.
//

import UIKit
import UIImageColors
import WidgetKit

struct ChannelTimelineEntry<T: ChannelConfigurationIntent>: TimelineEntry {
    let date: Date

    let state: State

    let intent: T
    let context: TimelineProviderContext

    enum State: CustomStringConvertible {
        case data(ChannelPosterData)
        case noData(displayName: String)
        case unconfigured

        var description: String {
            switch self {
            case .data(let data):
                data.status.description
            case .noData(displayName: let displayName):
                "No data for \(displayName)"
            case .unconfigured:
                "Unconfigured"
            }
        }
    }

    struct ChannelPosterData {
        var loginName: String
        var displayName: String
        var profileImage: ProfileImage

        var status: Status

        enum Status: CustomStringConvertible {
            case online(_ gameName: String, startedAt: Date, viewerCount: Int)
            case offline

            var description: String {
                switch self {
                case .online(let gameName, startedAt: let startedAt, viewerCount: let viewerCount):
                    "Game: \(gameName), live at \(startedAt.description(with: .current)), viewer count \(viewerCount)"
                case .offline:
                    "Offline"
                }
            }
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
