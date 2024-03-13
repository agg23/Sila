//
//  PickerTabView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/19/24.
//

import SwiftUI

struct PickerTabView<LeftContent: View, RightContent: View>: View {
    @State private var leftActive = true

    let leftTitle: String
    let leftView: () -> LeftContent

    let rightTitle: String
    let rightView: () -> RightContent

    var body: some View {
        TabView(selection: $leftActive) {
            self.leftView()
                .tag(true)

            self.rightView()
                .tag(false)
        }
        // Prevent the displayed views from animating
        .animation(nil, value: self.leftActive)
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ornament(attachmentAnchor: .scene(.bottom)) {
            Ornament(leftTitle: self.leftTitle, rightTitle: self.rightTitle, leftActive: $leftActive)
        }
    }
}

// For some reason we can't animate the background color change when this is inline, or in a separate
// viewbuilder function
private struct Ornament: View {
    let leftTitle: String
    let rightTitle: String

    @Binding var leftActive: Bool

    var body: some View {
        HStack {
            Button(self.leftTitle) {
                withAnimation {
                    self.leftActive = true
                }
            }
            .tint(.white.opacity(0.4))
            .highlightableButton(self.leftActive)

            Button(self.rightTitle) {
                withAnimation {
                    self.leftActive = false
                }
            }
            .tint(.white.opacity(0.4))
            .highlightableButton(!self.leftActive)
        }
        .padding(8)
        .glassBackgroundEffect()
    }
}

#Preview {
    PickerTabView(leftTitle: "Left", leftView: {
        Text("This is left")
    }, rightTitle: "Right", rightView: {
        Text("This is right")
    })
}
