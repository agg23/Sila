//
//  TagView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/18/24.
//

import SwiftUI

struct TagView: View {
    let text: String

    var body: some View {
        Text(text)
            .fixedSize()
            .font(.caption2.weight(.bold))
            .padding(.all, 4)
            .background(RoundedRectangle(cornerRadius: 5).stroke())
            .foregroundStyle(.secondary)
    }
}

#Preview {
    HStack {
        TagView(text: "Tag 1")
        TagView(text: "Another Tag")
        TagView(text: "Yet Another")
    }
}
