//
//  ViewerCountView.swift
//  Sila
//
//  Created by Adam Gastineau on 10/28/25.
//

import SwiftUI

struct ViewerCountView: View {
    let viewerCount: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: Icon.viewerCount)
                .symbolRenderingMode(.palette)
                .foregroundStyle(.red, .white)
            Text(self.viewerCount.formatted(.number))
                .monospacedDigit()
                .lineLimit(1)
        }
    }
}
