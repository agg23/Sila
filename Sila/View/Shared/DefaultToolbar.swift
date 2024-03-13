//
//  DefaultToolbar.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/19/24.
//

import SwiftUI

func defaultToolbar() -> some ToolbarContent {
    return ToolbarItem(placement: .topBarTrailing) {
        AuthBadgeView()
    }
}
