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

    let ignoreSafeArea: Bool

    let action: (() -> Void)?

    internal init(title: String, systemImage: String, description: String, buttonTitle: String, buttonSystemImage: String, ignoreSafeArea: Bool = false, action: (() -> Void)? = nil) {
        self.title = title
        self.systemImage = systemImage
        self.description = description
        self.buttonTitle = buttonTitle
        self.buttonSystemImage = buttonSystemImage
        self.ignoreSafeArea = ignoreSafeArea
        self.action = action
    }

    var body: some View {
        if self.ignoreSafeArea {
            // Vertically center content with NavigationStack safe area
            ZStack {
                Color.clear
                self.content
            }
            .ignoresSafeArea()
        } else {
            self.content
        }
    }

    @ViewBuilder
    var content: some View {
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
