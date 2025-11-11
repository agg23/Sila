//
//  ChatPresentableController.swift
//  Sila
//
//  Created by Adam Gastineau on 11/9/25.
//

import Foundation

final class ChatPresentableController: PresentableControllerBase {
    let chatModel: ChatModel

    var task: Task<Void, Never>?

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
