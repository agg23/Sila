//
//  PickerTabView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/19/24.
//

import SwiftUI

struct OrnamentPickerTabView<LeftContent: View, RightContent: View>: View {
    @Environment(\.disablePrimaryOrnaments) private var disablePrimaryOrnaments

    @State private var leftActive = true

    let leftTitle: String
    @ViewBuilder var leftView: () -> LeftContent

    let rightTitle: String
    @ViewBuilder var rightView: () -> RightContent

    var body: some View {
        #if os(tvOS)
        // A nested TabView fights the main sidebar TabView for focus, so use a plain picker instead
        VStack(spacing: 0) {
            Picker("", selection: $leftActive) {
                Text(self.leftTitle)
                    .tag(true)
                Text(self.rightTitle)
                    .tag(false)
            }
            .pickerStyle(.segmented)
            .fixedSize()

            if self.leftActive {
                self.leftView()
            } else {
                self.rightView()
            }
        }
        #else
        TabView(selection: $leftActive) {
            self.leftView()
                .tag(true)

            self.rightView()
                .tag(false)
        }
        // Prevent the displayed views from animating
        .animation(nil, value: self.leftActive)
        #if os(visionOS)
        .tabViewStyle(.page(indexDisplayMode: .never))
        #endif
        #if os(visionOS)
        .ornament(visibility: self.disablePrimaryOrnaments ? .hidden : .automatic, attachmentAnchor: .scene(.bottom)) {
            Ornament(leftTitle: self.leftTitle, rightTitle: self.rightTitle, leftActive: $leftActive)
        }
        #endif
        #endif
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
        #if os(visionOS)
        .glassBackgroundEffect()
        #else
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        #endif
    }
}

#Preview {
    OrnamentPickerTabView(leftTitle: "Left", leftView: {
        Text("This is left")
    }, rightTitle: "Right", rightView: {
        Text("This is right")
    })
}
