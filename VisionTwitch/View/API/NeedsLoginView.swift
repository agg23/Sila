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

    var body: some View {
        VStack {
            Text("To view \(self.noAuthMessage)")
            Button {
                self.authController.requestReauth()
            } label: {
                Text("Log In")
            }
        }
    }
}

#Preview {
    NeedsLoginView(noAuthMessage: "this view")
}
