//
//  SettingsView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 3/4/24.
//

import SwiftUI

struct SettingsView: View {
    @Environment(Router.self) private var router

    @AppStorage(Setting.hideMature) var hideMature: Bool = false
    @AppStorage(Setting.disableIncrementingStreamDuration) var disableIncrementingStreamDuration: Bool = false

    @AppStorage(Setting.smallBorderRadius) var smallBorderRadius: Bool = false
    @AppStorage(Setting.dimSurroundings) var dimSurroundings: Bool = false

    var body: some View {
        VStack {
            Form {
                Section("Navigation") {
                    Toggle(isOn: self.$hideMature) {
                        Text("Hide Mature Streams")
                        Text("Will not hide mature streams from streamers you follow")
                    }
                    Toggle(isOn: self.$disableIncrementingStreamDuration) {
                        Text("Disable Updating Stream Durations")
                        Text("Minimizes motion by displaying a static duration for a live stream")
                    }
                }

                Section("Playback") {
                    Toggle("Shrink Video Corners", isOn: self.$smallBorderRadius)
                    Toggle("Dim Surroundings", isOn: self.$dimSurroundings)
                }

                Section {
                    NavigationLink {
                        LicensesView()
                    } label: {
                        Label("Licenses", systemImage: "newspaper")
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
    }
}

#Preview {
    NavStack {
        SettingsView()
    }
}
