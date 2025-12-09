//
//  ChannelPosterView.swift
//  WidgetsExtension
//
//  Created by Adam Gastineau on 12/7/25.
//

import SwiftUI
import WidgetKit
import UIImageColors

struct ChannelPosterView: View {
    let entry: ChannelPosterTimelineEntry

    var body: some View {
        Group {
            switch self.entry.state {
            case .data(let data):
                let state: ProfilePoster.State = switch data.status {
                case .online(let gameName, _, _):
                    // TODO: Implement live stream info
                    .online(gameName: gameName)
                case .offline:
                    .offline
                }

                ProfilePoster(loginName: data.loginName, displayName: data.displayName, state: state, image: data.profileImage, widgetFamily: self.entry.context.family, displayChannelName: self.entry.intent.displayChannelName)
            case .noData(let displayName):
                // TODO: Finish this
                VStack {
                    Text("Unable to fetch \(displayName)")
                }
            case .unconfigured:
                ProfilePoster(loginName: nil, displayName: "Sila", state: .online(gameName: "Watching streams"), image: ProfileImage.unfetched, widgetFamily: self.entry.context.family, displayChannelName: true)
            }
        }
    }
}

struct ProfilePoster: View {
    let loginName: String?
    let displayName: String

    let state: State
    let image: ProfileImage

    let widgetFamily: WidgetFamily

    let displayChannelName: Bool

    var isSmall: Bool {
        if case .systemSmall = self.widgetFamily {
            true
        } else {
            false
        }
    }

    var isOnline: Bool {
        if case .online(gameName: _) = self.state {
            true
        } else {
            false
        }
    }

    var gameName: String {
        if case .online(gameName: let gameName) = self.state {
            gameName
        } else {
            "Offline"
        }
    }

    var body: some View {
        let url: URL? = if let loginName = self.loginName {
            URL(string: "sila://watch?stream=\(loginName)")
        } else {
            nil
        }

        VStack(spacing: 0) {
            Image(uiImage: self.image.image)
                .resizable()
                .aspectRatio(1.0, contentMode: .fit)
                // Outer widget border radius is 24
                .clipShape(.rect(cornerRadius: 24 - 12))
                .padding(.bottom, 8)

            VStack {
                if self.displayChannelName {
                    Text(self.displayName)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .font(self.isSmall ? .title2 : .title)
                        .foregroundStyle(Color(cgColor: self.image.colors.primary.cgColor))
                }

                Text(self.gameName.isEmpty ? "Live" : self.gameName)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .font(self.isSmall ? .title3 : .title2)
                    .foregroundStyle(Color(cgColor: self.image.colors.secondary.cgColor))
            }
            .padding(.horizontal, 16)

            Spacer(minLength: 0)
        }
        .padding(12)
        .opacity(self.isOnline ? 1.0 : 0.7)
        .containerBackground(Color(cgColor: self.image.colors.background.cgColor), for: .widget)
        .widgetURL(url)
    }

    enum State {
        case online(gameName: String)
        case offline
    }
}

