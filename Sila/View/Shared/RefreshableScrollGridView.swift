//
//  RefreshableScrollGridView.swift
//  Sila
//
//  Created by Adam Gastineau on 3/17/24.
//

import SwiftUI

struct RefreshableScrollGridView<T, Content: View>: View {
    let loader: StandardDataLoader<T>

    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollGridView {
            self.content()
            if self.loader.isLoadingMore() {
                ProgressView()
            }
        }
        .refreshable(action: { try? await self.loader.refresh(minDurationSecs: 1) })

    }
}
