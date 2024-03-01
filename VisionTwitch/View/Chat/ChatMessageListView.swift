//
//  ChatMessageListView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/29/24.
//

import SwiftUI
import TwitchIRC

struct ChatMessageListView: View {
    let messages: [PrivateMessage]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack {
                    ForEach(self.messages) { message in
                        ChatMessageView(message: message)
                    }

                    Color.clear
                        .frame(width: 0, height: 0, alignment: .bottom)
//                        .onAppear {
//                            self.scrollAtBottom = true
//                        }
//                        .onDisappear {
//                            self.scrollAtBottom = false
//                        }
                }
            }
            .onChange(of: self.messages.last ?? PrivateMessage(), { _, newValue in
//                guard self.scrollAtBottom else {
//                    return
//                }

                proxy.scrollTo(newValue)
            })
            .onAppear {
                proxy.scrollTo(self.messages.last)
            }
        }

    }
}

#Preview {
    ChatMessageListView(messages: PRIVATEMESSAGE_LIST_MOCK())
}
