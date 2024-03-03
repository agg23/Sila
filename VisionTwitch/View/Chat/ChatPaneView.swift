//
//  ChatPaneView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 3/2/24.
//

import SwiftUI
import VisionPane

struct ChatPaneView: View {
    @Environment(\.dismissPane) var dismissPane

    let channel: String

    var body: some View {
        NavigationStack {
            ChatView(channel: self.channel)
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
        }
    }
}

#Preview {
    ChatPaneView(channel: "barbarousking")
}
