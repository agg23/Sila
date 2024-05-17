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
            print("Logging global \(emote)")
            return emote
        }

        let emote = self.userEmotes[named]
        
        if let emote = emote {
            print("Logging \(emote)")
        }

        return emote
    }

    func fetchGlobalEmotes() async {
        if !self.globalEmotes.isEmpty {
            return
        }

        async let sevenTV: Void = self.fetchSevenTVGlobalEmotes()
        async let betterTTV: Void = self.fetchBetterTTVGlobalEmotes()

        let _ = await (sevenTV, betterTTV)
    }

    func fetchUserEmotes(for id: String) async {
        self.userEmotes = [:]

        async let sevenTV: Void = self.fetchSevenTVUserEmotes(for: id)
        async let betterTTV: Void = self.fetchBetterTTVUserEmotes(for: id)

        let _ = await (sevenTV, betterTTV)
    }

    private func add(emote: Emote, output: inout [String: Emote]) {
        if let existingEmote = output[emote.name],
           !emote.isHigherPriority(than: existingEmote.source) {
            // There's an existing emote, but it's higher priority than our current one
            // Do nothing
            return
        }

        output[emote.name] = emote
    }

    // MARK: - 7TV

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
            print("7TV global request failed")
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
            print("7TV user request failed")
        }
    }

    private func decodeSevenTV(emote: SevenTVEmote, output: inout [String: Emote]) {
        // We ignore the file names provided by the API and just always check for a 1x scale, in _GIF_ form. The API
        // does not advertise GIFs, but we can't readily display animated AVIF or WEBP, and the GIFs appear to exist
        guard let url = URL(string: "https:\(emote.data.host.url)/1x.gif") else {
            print("Could not create URL for 7TV emote \(emote.name)")
            return
        }

        self.add(emote: Emote(name: emote.name, imageUrl: url, source: .sevenTV), output: &output)
    }

    // MARK: - BetterTTV

    private func fetchBetterTTVGlobalEmotes() async {
        do {
            let (data, _) = try await URLSession.shared.data(from: URL(string: "https://api.betterttv.net/3/cached/emotes/global")!)

            guard let betterTTVEmotes = try? JSONDecoder().decode([BetterTTVEmote].self, from: data) else {
                return
            }

            for emote in betterTTVEmotes {
                self.decodeBetterTTV(emote: emote, output: &self.globalEmotes)
            }
        } catch {
            print("BetterTTV global request failed")
        }
    }

    private func fetchBetterTTVUserEmotes(for id: String) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: URL(string: "https://api.betterttv.net/3/cached/users/twitch/\(id)")!)

            guard let betterTTVEmoteSet = try? JSONDecoder().decode(BetterTTVEmoteSet.self, from: data) else {
                return
            }

            for emote in betterTTVEmoteSet.channelEmotes + betterTTVEmoteSet.sharedEmotes {
                self.decodeBetterTTV(emote: emote, output: &self.userEmotes)
            }
        } catch {
            print("BetterTTV user request failed")
        }
    }

    private func decodeBetterTTV(emote: BetterTTVEmote, output: inout [String: Emote]) {
        // We ignore the file names provided by the API and just always check for a 1x scale, in _GIF_ form. The API
        // does not advertise GIFs, but we can't readily display animated AVIF or WEBP, and the GIFs appear to exist
        guard let url = URL(string: "https://cdn.betterttv.net/emote/\(emote.id)/1x") else {
            print("Could not create URL for BetterTTV emote \(emote.code)")
            return
        }

        self.add(emote: Emote(name: emote.code, imageUrl: url, source: .betterTTV), output: &output)
    }
}
