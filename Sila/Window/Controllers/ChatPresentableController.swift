//
//  ChatPresentableController.swift
//  Sila
//
//  Created by Adam Gastineau on 11/9/25.
//

import Foundation

final class ChatPresentableController: PresentableControllerBase {
    let chatModel: ChatModel
    var chatWindowModel: ChatWindowModel?

    private var task: Task<Void, Never>?

    static func contentId(for userId: String) -> String {
        "chat-\(userId)"
    }

    init(contentId: String, chatModel: ChatModel) {
        self.chatModel = chatModel
        super.init(contentId: contentId)
    }

    override func didBecomeHidden() async {
        self.task?.cancel()
        self.task = nil
    }

    override func didBecomeVisible() async {
        self.task = Task {
            await self.chatModel.connect()
        }
    }
}
