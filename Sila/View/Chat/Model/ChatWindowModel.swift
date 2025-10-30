//
//  ChatWindowModel.swift
//  Sila
//
//  Created by Adam Gastineau on 10/29/25.
//

import Foundation

struct ChatWindowModel: Encodable, Decodable, Hashable {
    let channelName: String
    let userId: String
    let title: String
}
