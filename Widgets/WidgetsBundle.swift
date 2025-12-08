//
//  WidgetsBundle.swift
//  Widgets
//
//  Created by Adam Gastineau on 12/5/25.
//

import WidgetKit
import SwiftUI

@main
struct WidgetsBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
//        StreamListWidget()
        ChannelPosterWidget()
    }
}
