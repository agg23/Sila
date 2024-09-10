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

    let width = 700.0

    let libraries = ["AsyncAnimatedImage", "JunoUI", "KeychainWrapper", "Nuke", "swift-twitch-client", "TwitchIRC"]

    var body: some View {
        ScrollView {
            VStack {
                Text("Project is available under MIT license")

                Button {
                    openURL(URL(string: "https://github.com/agg23/Sila")!)
                } label: {
                    Text("https://github.com/agg23/Sila")
                        .tint(.white)
                }

                Divider()
                    .padding(.vertical)

                Text("All upstream projects are MIT licensed, with the following respective copyrights. The MIT license text is produced at the bottom for your convience.")
                    .frame(width: self.width)

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
                .frame(width: self.width)
                .padding(.vertical)

                Text("MIT License")
                    .font(.title)
                    .padding(.bottom)

                Text("MIT", tableName: "Licenses")
                    .frame(width: self.width)
            }
            .padding(.vertical)
        }
        .largeNavigationTitle("Licenses")
    }
}

#Preview {
    LicensesView()
}
