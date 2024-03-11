//
//  SettingsView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 3/4/24.
//

import SwiftUI

struct SettingsView: View {
    @Environment(Router.self) private var router

    @AppStorage(Setting.smallBorderRadius) var smallBorderRadius: Bool = false
    @AppStorage(Setting.hideMature) var hideMature: Bool = false

    var body: some View {
        VStack {
            Form {
                Section {
//                    Toggle("Shrink Video Corners", isOn: self.$smallBorderRadius)
                    Toggle(isOn: self.$hideMature) {
                        Text("Hide Mature Streams")
                        Text("Will not hide mature streams from streamers you follow")
                    }
                }
            }
            Button {
                self.router.path.append(.settingsLicenses)
            } label: {
                Label("Licenses", systemImage: "newspaper")
            }
        }
    }
}

#Preview {
    NavStack {
        SettingsView()
    }
}
