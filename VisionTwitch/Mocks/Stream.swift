//
//  Stream.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/18/24.
//

import Foundation
import Twitch

func STREAMS_LIST_MOCK() -> [Twitch.Stream] {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"

    let baseStreams = [Twitch.Stream(id: "42322153657", userId: "22510310", userLogin: "gamesdonequick", userName: "GamesDoneQuick", gameID: "18808", gameName: "Resident Evil 5", type: "live", title: "Unapologetically Black and Fast 2024 - Resident Evil 5 speedrun by @Sprinkle_Theory and @SuperNamu !schedule !ubaf", language: "en", tags: ["English", "speedrun"], isMature: false, viewerCount: 2126, startedAt: dateFormatter.date(from: "2024-02-17 22:56:55 +0000")!, thumbnailURL: "https://static-cdn.jtvnw.net/previews-ttv/live_user_gamesdonequick-{width}x{height}.jpg"), Twitch.Stream(id: "40460498981", userId: "20786541", userLogin: "yogscast", userName: "Yogscast", gameID: "18846", gameName: "Garry\'s Mod", type: "live", title: "YogsCinema - Osie\'s Insane Life Stories | Gmod TTT XL", language: "en", tags: ["English", "NoBackseating", "Variety"], isMature: false, viewerCount: 199, startedAt: dateFormatter.date(from: "2024-02-17 22:56:55 +0000")!, thumbnailURL: "https://static-cdn.jtvnw.net/previews-ttv/live_user_yogscast-{width}x{height}.jpg"), Twitch.Stream(id: "50428025309", userId: "10217631", userLogin: "patty", userName: "Patty", gameID: "766571430", gameName: "HELLDIVERS 2", type: "live", title: "I\'M DOING MY PART", language: "en", tags: ["Bald", "Masculine", "GigaChad", "Nobackseating", "NoTipsJustSips", "NoNUTHIN", "English", "NoHints", "NoHelp", "NoHelpUnlessAsked"], isMature: true, viewerCount: 61, startedAt: dateFormatter.date(from: "2024-02-18 04:02:27 +0000")!, thumbnailURL: "https://static-cdn.jtvnw.net/previews-ttv/live_user_patty-{width}x{height}.jpg")]

    return baseStreams + baseStreams.map({ stream in
        return Twitch.Stream(id: "\(stream.id)1", userId: stream.userId, userLogin: stream.userLogin, userName: stream.userName, gameID: stream.gameID, gameName: stream.gameName, type: stream.type, title: stream.title, language: stream.language, tags: stream.tags, isMature: stream.isMature, viewerCount: stream.viewerCount, startedAt: stream.startedAt, thumbnailURL: stream.thumbnailURL)
    }) + baseStreams.map({ stream in
        return Twitch.Stream(id: "\(stream.id)2", userId: stream.userId, userLogin: stream.userLogin, userName: stream.userName, gameID: stream.gameID, gameName: stream.gameName, type: stream.type, title: stream.title, language: stream.language, tags: stream.tags, isMature: stream.isMature, viewerCount: stream.viewerCount, startedAt: stream.startedAt, thumbnailURL: stream.thumbnailURL)
    })
}

func STREAM_MOCK() -> Twitch.Stream {
    return STREAMS_LIST_MOCK()[0]
}
