//
//  SingleChannelView.swift
//  WidgetsExtension
//
//  Created by Adam Gastineau on 12/7/25.
//

import SwiftUI
import WidgetKit
import UIImageColors

struct SingleChannelView<T: ChannelConfigurationIntent>: View {
    let entry: ChannelTimelineEntry<T>

    var body: some View {
        switch self.entry.state {
        case .data(let data):
            let state: ProfileStatusView.State = switch data.status {
            case .online(let gameName, let streamTitle, let startedAt, let viewerCount):
                .online(gameName, streamTitle: streamTitle, startedAt: startedAt, viewerCount: viewerCount)
            case .offline:
                .offline
            }

            ProfileStatusView(loginName: data.loginName, displayName: data.displayName, state: state, image: data.profileImage, widgetFamily: self.entry.context.family, displayChannelName: self.entry.intent.displayChannelName)
        case .noData(let displayName):
            ProfileStatusView(loginName: nil, displayName: displayName, state: .offline, image: ProfileImage.unfetched, widgetFamily: self.entry.context.family, displayChannelName: true)
        case .unconfigured:
            ProfileStatusView(loginName: nil, displayName: "Sila", state: .unknown, image: ProfileImage.unfetched, widgetFamily: self.entry.context.family, displayChannelName: true)
        }
    }
}

struct ProfileStatusView: View {
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
        switch self.state {
        case .online(let gameName, _, _, _):
            gameName
        case .unknown:
            "Watching streams"
        case .offline:
            "Offline"
        }
    }

    var title: String? {
        if case .online(_, streamTitle: let streamTitle, startedAt: _, viewerCount: _) = self.state {
            streamTitle
        } else {
            nil
        }
    }

    var body: some View {
        let url: URL? = if let loginName = self.loginName {
            URL(string: "sila://watch?stream=\(loginName)")
        } else {
            nil
        }

        let isHorizontal = self.widgetFamily == .systemMedium

        self.mainStack(isHorizontal) {
            VStack(alignment: isHorizontal ? .leading : .center) {
                self.displayNameText()
                self.gameNameText()
                self.titleText()
            }
        }
        .padding(12)
        .opacity(self.isOnline ? 1.0 : 0.7)
        .containerBackground(Color(cgColor: self.image.colors.background.cgColor), for: .widget)
        .widgetURL(url)
    }

    @ViewBuilder
    func mainStack<T: View>(_ isHorizontal: Bool, _ body: () -> T) -> some View {
        if isHorizontal {
            HStack(alignment: .top) {
                ProfileImageView(image: self.image.image)
                    .padding(.trailing, 8)

                body()
                    .padding(.top, 8)

                Spacer(minLength: 0)
            }
        } else {
            VStack {
                ProfileImageView(image: self.image.image)
                    .padding(.bottom, 8)

                body()

                Spacer(minLength: 0)
            }
        }
    }

    @ViewBuilder
    func displayNameText() -> some View {
        if self.displayChannelName {
            Text(self.displayName)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .font(self.isSmall ? .title2 : .title)
                .foregroundStyle(Color(cgColor: self.image.colors.primary.cgColor))
        }
    }

    @ViewBuilder
    func gameNameText() -> some View {
        Text(self.gameName.isEmpty ? "Live" : self.gameName)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .font(self.isSmall ? .title3 : .title2)
            .foregroundStyle(Color(cgColor: self.image.colors.secondary.cgColor))
    }

    @ViewBuilder
    func titleText() -> some View {
        if let title = self.title {
            Text(title)
                .lineLimit(1)
//                .minimumScaleFactor(0.5)
                .font(.body)
                .foregroundStyle(Color(cgColor: self.image.colors.secondary.cgColor))
        }
    }

    enum State {
        case online(_ gameName: String, streamTitle: String, startedAt: Date, viewerCount: Int)
        case unknown
        case offline
    }
}

