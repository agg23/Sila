//
//  LicensesView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 3/4/24.
//

import SwiftUI

extension LocalizedStringKey: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self)
    }
}

struct LicensesView: View {
    @Environment(\.openURL) private var openURL

    let libraries = ["Gifu", "JunoUI", "KeychainWrapper", "Nuke", "SubviewAttachingTextView", "swift-twitch-client", "TwitchIRC"]

    var body: some View {
        ScrollView {
            VStack {
                Text("Project is available under MIT license")

                Button {
                    openURL(URL(string: "https://github.com/agg23/VisionTwitch")!)
                } label: {
                    Text("https://github.com/agg23/VisionTwitch")
                        .tint(.white)
                }

                Divider()
                    .padding(.vertical)

                Text("All upstream projects are MIT licensed, with the following respective copyrights. The MIT license text is produced at the bottom for your convience.")
                    .frame(width: 700)

                GroupBox {
                    Grid(alignment: .leading) {
                        GridRow {
                            Text("Package")
                            Text("Copyright")
                        }
                        .font(.title)
                        .padding(.bottom)

                        ForEach(self.libraries, id: \.self) { library in
                            GridRow {
                                Text(library)
                                Text(LocalizedStringKey(library), tableName: "Licenses")
                            }
                        }
                    }
                }
                .frame(width: 700)
                .padding(.vertical)

                Text("MIT License")
                    .font(.title)
                    .padding(.bottom)

                Text("MIT", tableName: "Licenses")
                    .frame(width: 700)
            }
            .padding(.vertical)
        }
        .navigationTitle("Licenses")
    }
}

#Preview {
    LicensesView()
}
