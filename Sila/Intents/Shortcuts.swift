//
//  Shortcuts.swift
//  Sila
//
//  Created by Adam Gastineau on 3/18/24.
//

import AppIntents

class Shortcuts: AppShortcutsProvider {
    static var shortcutTileColor = ShortcutTileColor.pink

    static var appShortcuts: [AppShortcut] = [
        AppShortcut(intent: OpenStreamIntent(), phrases: [
                "Watch \(.applicationName) stream",
                "Watch stream in \(.applicationName)",
                "Open \(.applicationName) stream",
                "Open stream in \(.applicationName)",
                "Watch twitch stream",
                "Watch livestream"
            ],
            shortTitle: "Open Stream",
            systemImageName: "tv"),

        AppShortcut(intent: LiveFollowingStreamsIntent(), phrases: [
                "View live followed channels in \(.applicationName)",
                "Who is live in \(.applicationName)",
            ],
            shortTitle: "Live Following Channels",
            systemImageName: "person.crop.square.badge.video.fill"),

        AppShortcut(intent: PopularStreamsIntent(), phrases: [
                "View popular channels in \(.applicationName)",
                "Who is most popular on \(.applicationName)",
            ],
            shortTitle: "Most Popular Streams",
            systemImageName: "star"),

        AppShortcut(intent: CategoryStreamsIntent(), phrases: [
                "View popular streams for game in \(.applicationName)",
                "Who is streaming in category on \(.applicationName)",
            ],
            shortTitle: "Streams in Category",
            systemImageName: "gamecontroller")
    ]
}
