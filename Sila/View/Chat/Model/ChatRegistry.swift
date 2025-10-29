//
//  ChatRegistry.swift
//  Sila
//
//  Created by Adam Gastineau on 10/28/25.
//

import Foundation

final class ChatRegistry {
    static let shared = ChatRegistry()

    var registry: [String: ChatModel] = [:]

    func model(for channelName: String, with userId: String) -> ChatModel {
        if let existingModel = self.registry[channelName] {
            return existingModel
        }

        let model = ChatModel(channelName: channelName, userId: userId)
        self.registry[channelName] = model
        return model
    }
}
