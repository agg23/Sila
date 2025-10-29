//
//  HistoryStore.swift
//  VisionTwitch
//
//  Created for issue #42
//

import Foundation
import Twitch

/// Manages search history and recently opened stream history using UserDefaults
class HistoryStore: ObservableObject {
    static let shared = HistoryStore()
    
    private let searchHistoryKey = "searchHistory"
    private let recentStreamsKey = "recentStreams"
    private let maxHistoryItems = 20
    
    @Published var searchHistory: [String] = []
    @Published var recentStreams: [RecentStream] = []
    
    private init() {
        loadSearchHistory()
        loadRecentStreams()
    }
    
    // MARK: - Search History
    
    func addSearchQuery(_ query: String) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        self.searchHistory.removeAll { $0 == query }
        self.searchHistory.insert(query, at: 0)
        
        if self.searchHistory.count > self.maxHistoryItems {
            self.searchHistory = Array(self.searchHistory.prefix(self.maxHistoryItems))
        }
        
        self.saveSearchHistory()
    }
    
    func clearSearchHistory() {
        self.searchHistory = []
        self.saveSearchHistory()
    }
    
    private func loadSearchHistory() {
        if let data = UserDefaults.standard.array(forKey: self.searchHistoryKey) as? [String] {
            self.searchHistory = data
        }
    }
    
    private func saveSearchHistory() {
        UserDefaults.standard.set(self.searchHistory, forKey: self.searchHistoryKey)
    }
    
    func addRecentStream(_ stream: Twitch.Stream) {
        let recentStream = RecentStream(
            userLogin: stream.userLogin,
            userName: stream.userName
        )
        
        self.recentStreams.removeAll { $0.userLogin == stream.userLogin }
        self.recentStreams.insert(recentStream, at: 0)
        
        if self.recentStreams.count > self.maxHistoryItems {
            self.recentStreams = Array(self.recentStreams.prefix(self.maxHistoryItems))
        }
        
        self.saveRecentStreams()
    }
    
    func clearRecentStreams() {
        self.recentStreams = []
        self.saveRecentStreams()
    }
    
    private func loadRecentStreams() {
        if let data = UserDefaults.standard.data(forKey: self.recentStreamsKey),
           let decoded = try? JSONDecoder().decode([RecentStream].self, from: data) {
            self.recentStreams = decoded
        }
    }
    
    private func saveRecentStreams() {
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
