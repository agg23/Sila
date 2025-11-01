//
//  RecentsStore.swift
//  VisionTwitch
//

import Foundation
import Twitch

/// Manages search recents and recently opened channel recents using UserDefaults
class RecentsStore: ObservableObject {
    static let shared = RecentsStore()
    
    private let searchRecentsKey = "searchHistory"
    private let recentChannelsKey = "recentChannels"
    private let maxRecentsItems = 4
    
    @Published var searchRecents: [String] = []
    @Published var recentChannels: [RecentChannel] = []
    
    private init() {
        if let data = UserDefaults.standard.array(forKey: self.searchRecentsKey) as? [String] {
            self.searchRecents = data
        }
        
        if let data = UserDefaults.standard.data(forKey: self.recentChannelsKey),
           let decoded = try? JSONDecoder().decode([RecentChannel].self, from: data) {
            self.recentChannels = decoded
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
    
    func addRecentChannel(userLogin: String, userName: String, profileImageUrl: String) {
        let recentChannel = RecentChannel(
            userLogin: userLogin,
            userName: userName,
            profileImageUrl: profileImageUrl
        )
        
        self.recentChannels.removeAll { $0.userLogin == userLogin }
        self.recentChannels.insert(recentChannel, at: 0)
        
        if self.recentChannels.count > self.maxRecentsItems {
            self.recentChannels = Array(self.recentChannels.prefix(self.maxRecentsItems))
        }
        
        if let encoded = try? JSONEncoder().encode(self.recentChannels) {
            UserDefaults.standard.set(encoded, forKey: self.recentChannelsKey)
        }
    }
    
    func clearRecentChannels() {
        self.recentChannels = []
        if let encoded = try? JSONEncoder().encode(self.recentChannels) {
            UserDefaults.standard.set(encoded, forKey: self.recentChannelsKey)
        }
    }
}

struct RecentChannel: Codable, Identifiable {
    let userLogin: String
    let userName: String
    let profileImageUrl: String
    
    var id: String {
        self.userLogin
    }
}
