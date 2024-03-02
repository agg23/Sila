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
                .toolbar(content: {
                    
                })
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismissPane()
                        } label: {
                            Label("Dismiss", systemImage: "xmark")
                        }
                        .help("Dismiss")
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button {

                        } label: {
                            // TODO: Change this icon
                            Label("Pop Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                        .help("Pop Out")
                    }
                }
        }
    }
}

#Preview {
    ChatPaneView(channel: "barbarousking")
}
