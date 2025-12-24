//
//  RoundedBackground.swift
//  Sila
//
//  Created by Adam Gastineau on 12/23/25.
//

import SwiftUI

private struct RoundedBackground: ViewModifier {
    @AppStorage(Setting.smallBorderRadius) var smallBorderRadius: Bool = false

    let type: RoundedBackgroundType
    let enableSmallBorder: Bool

    func body(content: Content) -> some View {
        let clipShape = RoundedRectangle(cornerRadius: self.enableSmallBorder && self.smallBorderRadius ? Window.smallWindowCornerRadius : Window.largeWindowCornerRadius)

        switch self.type {
        case .glass:
            content
                .glassBackgroundEffect(in: clipShape)
        case .solid(let color):
            content
                .background(color)
                .clipShape(clipShape)
        }
    }
}

enum RoundedBackgroundType {
    case glass
    case solid(Color)
}

extension View {
    func roundedBackground(_ type: RoundedBackgroundType, enableSmallBorder: Bool = true) -> some View {
        self.modifier(RoundedBackground(type: type, enableSmallBorder: enableSmallBorder))
    }
}
