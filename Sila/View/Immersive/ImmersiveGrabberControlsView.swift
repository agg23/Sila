//
//  ImmersiveGrabberView.swift
//  Sila
//
//  Created by Adam Gastineau on 12/18/25.
//

import SwiftUI

struct ImmersiveGrabberControlsView: View {
//    @Namespace private var hoverNamespace

    @State private var isDragging: Bool = false

    let onDragChanged: (CGSize, Vector3D) -> Void
    let onDragEnded: () -> Void
    
    var body: some View {
//        let hoverGroup = HoverEffectGroup(self.hoverNamespace)

//        Rectangle()
//            .fill(.red)
        // This behaves really weirdly. Using .clear or a lower opacity means it won't properly detect hovers
        Color.white.opacity(0.001)
            .allowsHitTesting(true)
//            .contentShape(.rect)
            .overlay(alignment: .center, content: {
                ImmersiveGrabberPillView(isHeld: self.$isDragging)
            })
            .frame(width: 400, height: 140)
            // TODO: This makes the group cover the whole frame, but it also applies an shine effect
//            .hoverEffect()
            .hoverEffectGroup()
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace3D: .worldReference)
                    .onChanged { value in
                        if !self.isDragging {
                            self.isDragging = true
                        }
                        self.onDragChanged(value.translation, value.translation3D)
                    }
                    .onEnded { _ in
                        self.isDragging = false
                        self.onDragEnded()
                    }
            )
    }
}

struct ImmersiveGrabberPillView: View {
    @Binding var isHeld: Bool

//    let hoverGroup: HoverEffectGroup

    var body: some View {
        RoundedRectangle(cornerRadius: 8.5)
            .fill(.white)
            .frame(width: 226, height: 17)
            .scaleEffect(self.isHeld ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: self.isHeld)
            .hoverEffect { effect, isActive, proxy in
                effect.animation(.easeInOut(duration: 0.3)) { content in
                    content.opacity(isActive || self.isHeld ? 1.0 : 0.3)
                }
//                effect.opacity(isActive || self.isHeld ? 1.0 : 0.3)
            }
    }
}
