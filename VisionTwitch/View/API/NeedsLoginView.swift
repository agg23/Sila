//
//  NeedsLoginView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/25/24.
//

import SwiftUI

struct NeedsLoginView: View {
    @Environment(\.authController) private var authController

    let noAuthMessage: String
    let systemImage: String

    var body: some View {
        EmptyContentView(title: "Unauthorized", systemImage: self.systemImage, description: "To view \(self.noAuthMessage)", buttonTitle: "Log In", buttonSystemImage: "person") {
            self.authController.requestLoginReauthWithUI()
        }
    }
}

#Preview {
    NeedsLoginView(noAuthMessage: "this view", systemImage: "trash")
}
