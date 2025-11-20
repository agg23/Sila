//
//  ChatTextRenderer.swift
//  Sila
//
//  Created by Adam Gastineau on 11/19/25.
//

import SwiftUI

/// Renders emotes vertically centered in their lines
struct ChatTextRenderer: TextRenderer {
    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        for line in layout {
            for run in line {
                if let attribute = run[ChatImageAttribute.self] {
                    let actualWidth = attribute.size.width
                    let actualHeight = attribute.size.height

                    let y = line.typographicBounds.rect.midY - (actualHeight / 2.0)
                    let targetRect = CGRect(x: run.typographicBounds.rect.minX, y: y, width: actualWidth, height: actualHeight)

                    context.draw(attribute.image, in: targetRect)
                } else {
                    context.draw(run)
                }
            }
        }
    }
}

/// Attribute to mark image glyphs so we can modify their placement
struct ChatImageAttribute: TextAttribute, Hashable {
    let url: URL
    let image: Image
    let size: CGSize

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.url)
    }
}
