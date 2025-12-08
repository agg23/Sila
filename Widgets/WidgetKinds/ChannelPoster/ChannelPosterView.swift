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

                ProfilePoster(displayName: data.displayName, state: state, image: data.profileImage, widgetFamily: self.entry.context.family, displayChannelName: self.entry.intent.displayChannelName)
            case .noData(let displayName):
                VStack {
                    Text("Unable to fetch \(displayName)")
                }
            case .unconfigured(isPreview: let isPreview):
                let (displayName, gameName) = if isPreview {
                    ("Sila", "Watching streams")
                } else {
                    ("No channel", "")
                }

                ProfilePoster(displayName: displayName, state: .online(gameName: gameName), image: ProfileImage.unfetched, widgetFamily: self.entry.context.family, displayChannelName: true)
            }
        }
    }
}

struct ProfilePoster: View {
    let textBottomPadding = 8.0

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
        VStack(spacing: 4) {
            Image(uiImage: self.image.image)
                .resizable()
                .aspectRatio(1.0, contentMode: .fit)
                .clipShape(.rect(topLeadingRadius: 0, bottomLeadingRadius: 8, bottomTrailingRadius: 8, topTrailingRadius: 0))

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
            .padding(.top,
                     !self.isSmall ? 16 :
                     !self.displayChannelName ? self.textBottomPadding : 0)
            .padding(.horizontal, 16)

            Spacer(minLength: 0)
        }
        .padding(.bottom, self.textBottomPadding)
        .opacity(self.isOnline ? 1.0 : 0.7)
        .containerBackground(Color(cgColor: self.image.colors.background.cgColor), for: .widget)
    }

    enum State {
        case online(gameName: String)
        case offline
    }
}

