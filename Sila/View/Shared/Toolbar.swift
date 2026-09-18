//
//  Toolbar.swift
//  Sila
//
//  Created by Adam Gastineau on 7/11/26.
//

import SwiftUI

struct HidableToolbarItem<Content: View>: ToolbarContent {
    @Environment(\.enableToolbar) var enableToolbar

    let placement: ToolbarItemPlacement
    @ViewBuilder let content: Content

    var body: some ToolbarContent {
        ToolbarItem(placement: placement) {
            if enableToolbar {
                content
            } else {
                Spacer(minLength: 0)
            }
        }
    }
}

struct HidableToolbarItemGroup<Content: View>: ToolbarContent {
    @Environment(\.enableToolbar) var enableToolbar

    let placement: ToolbarItemPlacement
    @ViewBuilder let content: Content

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: placement) {
            if enableToolbar {
                content
            } else {
                Spacer(minLength: 0)
            }
        }
    }
}

var defaultToolbarPlacement: ToolbarItemPlacement {
    #if os(macOS)
    .primaryAction
    #else
    .topBarTrailing
    #endif
}

extension View {
    func defaultToolbarItem() -> some View {
        self.toolbar {
            HidableToolbarItem(placement: defaultToolbarPlacement) {
                AuthBadgeView()
            }
        }
    }
}
