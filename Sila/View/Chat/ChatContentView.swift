//
//  ChatPaneView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 3/2/24.
//

import SwiftUI

struct ChatContentView: View {
    @Environment(\.openWindow) private var openWindow

    let channelName: String
    let userId: String
    let title: String?
    let isWindow: Bool
    let dismissPane: () -> Void

    init(channelName: String, userId: String, title: String?, isWindow: Bool, dismissPane: @escaping () -> Void) {
        self.channelName = channelName
        self.userId = userId
        self.title = title
        self.isWindow = isWindow
        self.dismissPane = dismissPane
    }

    var body: some View {
        let title = self.title ?? "Chat"

        NavigationStack {
            ChatListView(channelName: self.channelName, userId: self.userId, isWindow: self.isWindow)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text(title)
                            .font(.title)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }

                    if !isWindow {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                self.dismissPane()
                            } label: {
                                Label("Dismiss", systemImage: Icon.close)
                            }
                            .help("Dismiss")
                        }

                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                let presentableController = PresentableControllerRegistry.shared(for: ChatPresentableController.self).controller(for: ChatPresentableController.contentId(for: self.userId))
                                let model = ChatWindowModel(channelName: self.channelName, userId: self.userId, title: title)
                                presentableController?.chatWindowModel = model
                                self.openWindow(id: Window.chat, value: model)
                                self.dismissPane()
                            } label: {
                                Label("Pop Out", systemImage: Icon.popOut)
                            }
                            .help("Pop Out")
                        }
                    } else {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                self.dismissPane()
                            } label: {
                                Label("Pop In", systemImage: Icon.popIn)
                            }
                            .help("Pop In")
                        }
                    }
                }
                // NavigationStack adds its own glass, so putting .background at its level doesn't work correctly
                .background(Color(red: 24.0/255.0, green: 24.0/255.0, blue: 27.0/255.0))
        }
    }
}

struct ChatPaneWindow: View {
    @Environment(\.dismissWindow) private var dismissWindow

    let channelName: String
    let userId: String
    let title: String

    var body: some View {
        ChatContentView(channelName: self.channelName, userId: self.userId, title: self.title, isWindow: true) {
            WindowController.shared.popoutChatSubject.send(self.userId)
            self.dismissWindow(id: Window.chat, value: ChatWindowModel(channelName: self.channelName, userId: self.userId, title: self.title))
        }
    }
}

#Preview {
    ChatContentView(channelName: "barbarousking", userId: "56865374", title: "BarbarousKing", isWindow: false) {
        print("Dismiss")
    }
}
