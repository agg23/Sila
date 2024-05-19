//
//  ChatPaneView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 3/2/24.
//

import SwiftUI

struct ChatPaneView: View {
    let channel: String
    let userId: String
    let title: String?
    let dismissPane: () -> Void

    var body: some View {
        NavigationStack {
            ChatView(channel: self.channel, userId: self.userId)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismissPane()
                        } label: {
                            Label("Dismiss", systemImage: "xmark")
                        }
                        .help("Dismiss")
                    }
                }
                .navigationTitle(self.title ?? "Chat")
        }
    }
}

#Preview {
    ChatPaneView(channel: "barbarousking", userId: "56865374", title: "BarbarousKing") {
        print("Dismiss")
    }
}
