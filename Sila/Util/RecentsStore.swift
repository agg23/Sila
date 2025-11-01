//
//  RecentsStore.swift
//  VisionTwitch
//
//  Created for issue #42
//

import Foundation
import Twitch

/// Manages search recents and recently opened stream recents using UserDefaults
class RecentsStore: ObservableObject {
    static let shared = RecentsStore()
    
    private let searchRecentsKey = "searchHistory"
    private let recentStreamsKey = "recentStreams"
    private let maxRecentsItems = 4
    
    @Published var searchRecents: [String] = []
    @Published var recentStreams: [RecentStream] = []
    
    private init() {
        if let data = UserDefaults.standard.array(forKey: self.searchRecentsKey) as? [String] {
            self.searchRecents = data
        }
        
        if let data = UserDefaults.standard.data(forKey: self.recentStreamsKey),
           let decoded = try? JSONDecoder().decode([RecentStream].self, from: data) {
            self.recentStreams = decoded
        }
    }
    
    // MARK: - Search Recents
    
    func addSearchQuery(_ query: String) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        self.searchRecents.removeAll { $0 == query }
        self.searchRecents.insert(query, at: 0)
        
        if self.searchRecents.count > self.maxRecentsItems {
            self.searchRecents = Array(self.searchRecents.prefix(self.maxRecentsItems))
        }
        
        UserDefaults.standard.set(self.searchRecents, forKey: self.searchRecentsKey)
    }
    
    func clearSearchRecents() {
        self.searchRecents = []
        UserDefaults.standard.set(self.searchRecents, forKey: self.searchRecentsKey)
    }
    
    func addRecentStream(_ stream: Twitch.Stream, resort: Bool = true) {
        let recentStream = RecentStream(
            userLogin: stream.userLogin,
            userName: stream.userName
        )
        
        if resort {
            self.recentStreams.removeAll { $0.userLogin == stream.userLogin }
            self.recentStreams.insert(recentStream, at: 0)
        } else {
            if !self.recentStreams.contains(where: { $0.userLogin == stream.userLogin }) {
                self.recentStreams.insert(recentStream, at: 0)
            }
        }
        
        if self.recentStreams.count > self.maxRecentsItems {
            self.recentStreams = Array(self.recentStreams.prefix(self.maxRecentsItems))
        }
        
        if let encoded = try? JSONEncoder().encode(self.recentStreams) {
            UserDefaults.standard.set(encoded, forKey: self.recentStreamsKey)
        }
    }
    
    func clearRecentStreams() {
        self.recentStreams = []
        if let encoded = try? JSONEncoder().encode(self.recentStreams) {
            UserDefaults.standard.set(encoded, forKey: self.recentStreamsKey)
        }
    }
}

struct RecentStream: Codable, Identifiable {
    let userLogin: String
    let userName: String
    
    var id: String {
        self.userLogin
    }
}
