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

    /// String: Emote
    var globalEmotes: NSMutableDictionary = [:]
    /// Inner dictionary is String: Emote
    var userToEmotes: [String: NSMutableDictionary] = [:]

    func getEmote(named: String, for userId: String) -> Emote? {
        if let emote = self.globalEmotes[named] as? Emote {
            #if DEBUG
            print("Logging global \(emote.source) \(emote.name)")
            #endif
            return emote
        }

        guard let userEmotes = self.userToEmotes[userId] else {
            return nil
        }

        let emote = userEmotes[named] as? Emote

        if let emote = emote {
            #if DEBUG
            print("Logging \(emote.source) \(emote.name) \(emote.imageUrl)")
            #endif
        }

        return emote
    }

    func fetchGlobalEmotes() async {
        if self.globalEmotes.count > 0 {
            return
        }

        async let sevenTV: Void = self.fetchSevenTVGlobalEmotes()
        async let betterTTV: Void = self.fetchBetterTTVGlobalEmotes()
        async let frankerFaceZ: Void = self.fetchFrankerFaceZGlobalEmotes()

        let _ = await (sevenTV, betterTTV, frankerFaceZ)
    }

    func fetchUserEmotes(for userId: String) async {
        self.userToEmotes[userId] = [:]

        async let sevenTV: Void = self.fetchSevenTVUserEmotes(for: userId)
        async let betterTTV: Void = self.fetchBetterTTVUserEmotes(for: userId)
        async let frankerFaceZ: Void = self.fetchFrankerFaceZUserEmotes(for: userId)

        let _ = await (sevenTV, betterTTV, frankerFaceZ)
    }

    private func add(emote: Emote, output: NSMutableDictionary) {
        if let existingEmote = output[emote.name] as? Emote,
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
                print("7TV global request failed")
                return
            }

            await self.decodeSevenTV(for: nil, emotes: sevenTVEmotes.emotes)
        } catch {
            print("7TV global request failed")
        }
    }

    private func fetchSevenTVUserEmotes(for id: String) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: URL(string: "https://7tv.io/v3/users/twitch/\(id)")!)

            guard let sevenTVUser = try? JSONDecoder().decode(SevenTVUser.self, from: data) else {
                print("7TV user request failed")
                return
            }

            await self.decodeSevenTV(for: id, emotes: sevenTVUser.emoteSet.emotes)
        } catch {
            print("7TV user request failed")
        }
    }

    @MainActor
    private func decodeSevenTV(for id: String?, emotes: [SevenTVEmote]) {
        guard let output = self.emoteWrapper(for: id) else {
            return
        }

        for emote in emotes {
            // We ignore the file names provided by the API and just always check for a 1x scale, in _GIF_ form. The API
            // does not advertise GIFs, but we can't readily display animated AVIF or WEBP, and the GIFs appear to exist
            guard let url = URL(string: "https:\(emote.data.host.url)/1x.gif") else {
                print("Could not create URL for 7TV emote \(emote.name)")
                return
            }

            self.add(emote: Emote(name: emote.name, imageUrl: url, source: .sevenTV), output: output)
        }
    }

    // MARK: - BetterTTV

    private func fetchBetterTTVGlobalEmotes() async {
        do {
            let (data, _) = try await URLSession.shared.data(from: URL(string: "https://api.betterttv.net/3/cached/emotes/global")!)

            guard let betterTTVEmotes = try? JSONDecoder().decode([BetterTTVEmote].self, from: data) else {
                print("BetterTTV global request failed")
                return
            }

            await self.decodeBetterTTV(for: nil, emotes: betterTTVEmotes)
        } catch {
            print("BetterTTV global request failed")
        }
    }

    private func fetchBetterTTVUserEmotes(for id: String) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: URL(string: "https://api.betterttv.net/3/cached/users/twitch/\(id)")!)

            guard let betterTTVEmoteSet = try? JSONDecoder().decode(BetterTTVEmoteSet.self, from: data) else {
                print("BetterTTV user request failed")
                return
            }

            await self.decodeBetterTTV(for: id, emotes: betterTTVEmoteSet.channelEmotes + betterTTVEmoteSet.sharedEmotes)
        } catch {
            print("BetterTTV user request failed")
        }
    }

    @MainActor
    private func decodeBetterTTV(for id: String?, emotes: [BetterTTVEmote]) {
        guard let output = self.emoteWrapper(for: id) else {
            return
        }

        for emote in emotes {
            // We ignore the file names provided by the API and just always check for a 1x scale, in _GIF_ form. The API
            // does not advertise GIFs, but we can't readily display animated AVIF or WEBP, and the GIFs appear to exist
            guard let url = URL(string: "https://cdn.betterttv.net/emote/\(emote.id)/1x") else {
                print("Could not create URL for BetterTTV emote \(emote.code)")
                return
            }

            self.add(emote: Emote(name: emote.code, imageUrl: url, source: .betterTTV), output: output)
        }
    }

    // MARK: - FrankerFaceZ

    private func fetchFrankerFaceZGlobalEmotes() async {
        do {
            let (data, _) = try await URLSession.shared.data(from: URL(string: "https://api.frankerfacez.com/v1/set/global")!)

            guard let frankerFaceZGlobalEmotes = try? JSONDecoder().decode(FrankerFaceZGlobalEmotes.self, from: data) else {
                print("FrankerFaceZ global request failed")
                return
            }

            for setId in frankerFaceZGlobalEmotes.defaultSets {
                if let set = frankerFaceZGlobalEmotes.sets[String(setId)] {
                    await self.decodeFrankerFaceZ(for: nil, set: set)
                }
            }
        } catch {
            print("FrankerFaceZ global request failed")
        }
    }

    private func fetchFrankerFaceZUserEmotes(for id: String) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: URL(string: "https://api.frankerfacez.com/v1/room/id/\(id)")!)

            do {
                let _ = try JSONDecoder().decode(FrankerFaceZRooms.self, from: data)
            } catch {
                print(error)
            }

            guard let frankerFaceZRooms = try? JSONDecoder().decode(FrankerFaceZRooms.self, from: data),
                  let set = frankerFaceZRooms.sets[String(frankerFaceZRooms.room.set)] else {
                print("FrankerFaceZ user request failed")
                return
            }

            await self.decodeFrankerFaceZ(for: id, set: set)
        } catch {
            print("FrankerFaceZ user request failed")
        }
    }

    @MainActor
    private func decodeFrankerFaceZ(for id: String?, set: FrankerFaceZEmoteSet) {
        guard let output = self.emoteWrapper(for: id) else {
            return
        }

        for emote in set.emoticons {
            if let animatedUrlString = emote.animated?["1"],
               let animatedUrl = URL(string: "\(animatedUrlString).gif") {
                // This is an animated emote. We append .gif to force GIFs
                self.add(emote: Emote(name: emote.name, imageUrl: animatedUrl, source: .frankerFaceZ), output: output)

                return
            }

            guard let urlString = emote.urls["1"],
                  let url = URL(string: urlString) else {
                print("Could not create URL for FrankerFaceZ emote \(emote.name)")
                return
            }

            self.add(emote: Emote(name: emote.name, imageUrl: url, source: .frankerFaceZ), output: output)
        }
    }

    private func emoteWrapper(for id: String?) -> NSMutableDictionary? {
        if let id = id {
            return self.userToEmotes[id]
        } else {
            return self.globalEmotes
        }
    }
}
