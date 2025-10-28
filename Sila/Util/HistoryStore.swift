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
        // Don't add empty strings
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        // Remove if it already exists (to move it to the front)
        searchHistory.removeAll { $0 == query }
        
        // Add to the beginning
        searchHistory.insert(query, at: 0)
        
        // Limit the size
        if searchHistory.count > maxHistoryItems {
            searchHistory = Array(searchHistory.prefix(maxHistoryItems))
        }
        
        saveSearchHistory()
    }
    
    func clearSearchHistory() {
        searchHistory = []
        saveSearchHistory()
    }
    
    private func loadSearchHistory() {
        if let data = UserDefaults.standard.array(forKey: searchHistoryKey) as? [String] {
            searchHistory = data
        }
    }
    
    private func saveSearchHistory() {
        UserDefaults.standard.set(searchHistory, forKey: searchHistoryKey)
    }
    
    // MARK: - Recent Streams
    
    func addRecentStream(_ stream: Twitch.Stream) {
        let recentStream = RecentStream(
            id: stream.id,
            userLogin: stream.userLogin,
            userName: stream.userName,
            gameName: stream.gameName,
            title: stream.title,
            viewerCount: stream.viewerCount,
            thumbnailURL: stream.thumbnailURL,
            timestamp: Date()
        )
        
        // Remove if it already exists (to move it to the front)
        recentStreams.removeAll { $0.userLogin == stream.userLogin }
        
        // Add to the beginning
        recentStreams.insert(recentStream, at: 0)
        
        // Limit the size
        if recentStreams.count > maxHistoryItems {
            recentStreams = Array(recentStreams.prefix(maxHistoryItems))
        }
        
        saveRecentStreams()
    }
    
    func clearRecentStreams() {
        recentStreams = []
        saveRecentStreams()
    }
    
    private func loadRecentStreams() {
        if let data = UserDefaults.standard.data(forKey: recentStreamsKey),
           let decoded = try? JSONDecoder().decode([RecentStream].self, from: data) {
            recentStreams = decoded
        }
    }
    
    private func saveRecentStreams() {
        if let encoded = try? JSONEncoder().encode(recentStreams) {
            UserDefaults.standard.set(encoded, forKey: recentStreamsKey)
        }
    }
}

/// Simplified representation of a stream for history tracking
struct RecentStream: Codable, Identifiable {
    let id: String
    let userLogin: String
    let userName: String
    let gameName: String
    let title: String
    let viewerCount: Int
    let thumbnailURL: String
    let timestamp: Date
}
