//
//  EmoteController.swift
//  Sila
//
//  Created by Adam Gastineau on 4/15/24.
//

import Foundation
import Network

class EmoteController {
    static let shared = EmoteController()

    var globalEmotes: [String: Emote] = [:]
    var userEmotes: [String: Emote] = [:]

    func getEmote(named: String) -> Emote? {
        if let emote = self.globalEmotes[named] {
            print("Logging 7TV global \(emote)")
            return emote
        }

        let emote = self.userEmotes[named]
        
        if let emote = emote {
            print("Logging 7TV \(emote)")
        }

        return emote
    }

    func fetchGlobalEmotes() async {
        if !self.globalEmotes.isEmpty {
            return
        }

        await self.fetchSevenTVGlobalEmotes()
    }

    func fetchUserEmotes(for id: String) async {
        self.userEmotes = [:]

        await self.fetchSevenTVUserEmotes(for: id)
    }

    private func fetchSevenTVGlobalEmotes() async {
        do {
            let (data, _) = try await URLSession.shared.data(from: URL(string: "https://7tv.io/v3/emote-sets/global")!)

            guard let sevenTVEmotes = try? JSONDecoder().decode(SevenTVGlobalEmotes.self, from: data) else {
                return
            }

            for emote in sevenTVEmotes.emotes {
                self.decodeSevenTV(emote: emote, output: &self.globalEmotes)
            }
        } catch {
            print("Request failed")
        }
    }

    private func fetchSevenTVUserEmotes(for id: String) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: URL(string: "https://7tv.io/v3/users/twitch/\(id)")!)

            guard let sevenTVUser = try? JSONDecoder().decode(SevenTVUser.self, from: data) else {
                return
            }

            for emote in sevenTVUser.emoteSet.emotes {
                self.decodeSevenTV(emote: emote, output: &self.userEmotes)
            }
        } catch {
            print("Request failed")
        }
    }

    private func decodeSevenTV(emote: SevenTVEmote, output: inout [String: Emote]) {
        // We ignore the file names provided by the API and just always check for a 1x scale, in _GIF_ form. The API
        // does not advertise GIFs, but we can't readily display animated AVIF or WEBP, and the GIFs appear to exist
        guard let url = URL(string: "https:\(emote.data.host.url)/1x.gif") else {
            print("Could not create URL for 7TV emote \(emote.name)")
            return
        }

        output[emote.name] = Emote(name: emote.name, imageUrl: url)
    }
}
