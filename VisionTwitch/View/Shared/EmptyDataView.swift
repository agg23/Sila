//
//  EmptyDataView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/26/24.
//

import SwiftUI

struct EmptyDataView: View {
    let title: String
    let systemImage: String
    let message: String
    let reload: (() -> Void)?

    var body: some View {
        VStack {
            ContentUnavailableView(self.title, systemImage: self.systemImage, description: Text("Could not find any \(self.message)."))
            if let reload = self.reload {
                Button("Reload", systemImage: "arrow.clockwise") {
                    reload()
                }
            }
        }
    }
}

#Preview {
    EmptyDataView(title: "Not found", systemImage: "nosign", message: "livestreams") {

    }
}
