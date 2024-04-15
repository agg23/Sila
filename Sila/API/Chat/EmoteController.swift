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

    func fetchGlobalEmotes() async {
        if !globalEmotes.isEmpty {
            return
        }

        await fetchSevenTVGlobalEmotes()
    }

    private func fetchSevenTVGlobalEmotes() async {
        do {
            let (data, _) = try await URLSession.shared.data(from: URL(string: "https://7tv.io/v3/emote-sets/global")!)

            guard let sevenTVEmotes = try? JSONDecoder().decode(SevenTVGlobalEmotes.self, from: data) else {
                return
            }

            for emote in sevenTVEmotes.emotes {
                if let file = emote.data.host.files.first(where: { file in
                    file.format == "AVIF" && file.name.starts(with: "1x")
                }) {
                    guard let url = URL(string: "https:\(emote.data.host.url)/\(file.name)") else {
                        print("Could not create URL for 7TV emote \(file.name)")
                        continue
                    }

                    self.globalEmotes[emote.name.lowercased()] = Emote(name: emote.name, imageUrl: url)
                }
            }
        } catch {
            print("Request failed")
        }
    }
}
