//
//  SettingsView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 3/4/24.
//

import SwiftUI

struct SettingsView: View {
    @Environment(Router.self) private var router

    var body: some View {
        Text("TODO: Add settings")
        Button {
            self.router.path.append(.settingsLicenses)
        } label: {
            Label("Licenses", systemImage: "newspaper")
        }
    }
}

#Preview {
    NavStack {
        SettingsView()
    }
}
