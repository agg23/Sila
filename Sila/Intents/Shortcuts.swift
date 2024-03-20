//
//  Shortcuts.swift
//  Sila
//
//  Created by Adam Gastineau on 3/18/24.
//

import AppIntents

class Shortcuts: AppShortcutsProvider {
    static var shortcutTileColor = ShortcutTileColor.pink

    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: OpenStreamIntent(), phrases: [
            "Watch \(.applicationName) stream",
            "Watch stream in \(.applicationName)",
            "Open \(.applicationName) stream",
            "Open stream in \(.applicationName)",
            "Watch twitch stream",
            "Watch livestream"
        ],
        shortTitle: "Open Stream",
        systemImageName: "tv")
    }
}
