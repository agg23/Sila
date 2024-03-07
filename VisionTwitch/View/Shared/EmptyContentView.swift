//
//  EmptyContentView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 3/6/24.
//

import SwiftUI

struct EmptyContentView: View {
    let title: String
    let systemImage: String
    let description: String

    let buttonTitle: String
    let buttonSystemImage: String
    let action: (() -> Void)?

    var body: some View {
        VStack {
            ContentUnavailableView(self.title, systemImage: self.systemImage, description: Text(self.description))
            if let action = self.action {
                Button(self.buttonTitle, systemImage: self.buttonSystemImage) {
                    action()
                }
                // Remove the large gap below the ContentUnavailableView
                .padding(.top, -20)
            }
        }
    }
}

#Preview {
    EmptyContentView(title: "Not found", systemImage: "nosign", description: "Description", buttonTitle: "Button", buttonSystemImage: "nose") {

    }
}
