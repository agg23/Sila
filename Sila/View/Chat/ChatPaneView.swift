//
//  ChatPaneView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 3/2/24.
//

import SwiftUI

struct ChatPaneView: View {
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
            ChatView(channelName: self.channelName, userId: self.userId)
                .toolbar {
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
                                self.openWindow(id: Window.chat, value: ChatWindowModel(channelName: self.channelName, userId: self.userId, title: title))
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
                .navigationTitle(title)
        }
        .glassBackgroundEffect(tint: Color(red: 24.0/255.0, green: 24.0/255.0, blue: 27.0/255.0))
    }
}

struct ChatPaneWindow: View {
    @Environment(\.dismissWindow) private var dismissWindow

    let channelName: String
    let userId: String
    let title: String

    var body: some View {
        ChatPaneView(channelName: self.channelName, userId: self.userId, title: self.title, isWindow: true) {
            WindowController.shared.popoutChatSubject.send(self.userId)
            dismissWindow(id: Window.chat, value: ChatWindowModel(channelName: self.channelName, userId: self.userId, title: self.title))
        }
    }
}

#Preview {
    ChatPaneView(channelName: "barbarousking", userId: "56865374", title: "BarbarousKing", isWindow: false) {
        print("Dismiss")
    }
}
