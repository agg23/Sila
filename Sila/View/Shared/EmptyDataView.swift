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
        EmptyContentView(title: self.title, systemImage: self.systemImage, description: "Could not find any \(self.message).", buttonTitle: "Reload", buttonSystemImage: "arrow.clockwise", ignoreSafeArea: true, action: self.reload)
    }
}

#Preview {
    EmptyDataView(title: "Not found", systemImage: "nosign", message: "livestreams") {

    }
}
