//
//  DarkBackgroundView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/25/24.
//

import SwiftUI

struct DarkBackgroundView<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        self.content()
            .background {
                Rectangle()
                    .foregroundStyle(
                        Color(white: 0.1, opacity: 0.25)
                            .shadow(.inner(color: .black.opacity(0.6), radius: 4.0, y: 2.0))
        //                    .shadow(.inner(color: .white, radius: 1.0, y: 0))
                    )
            }
    }
}

//struct DarkBackgroundShapeStyle: ShapeStyle {
//    func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
//        Color.red
////        Color(white: 0.1, opacity: 0.25)
////            .shadow(.inner(color: .black.opacity(0.6), radius: 4.0, y: 2.0))
//    }
//}
//
//extension ShapeStyle where Self == DarkBackgroundShapeStyle {
//    static var darkBackground: Self { .init() }
//}

#Preview {
    DarkBackgroundView {
        Text("hello world")
            .padding()
    }
}
