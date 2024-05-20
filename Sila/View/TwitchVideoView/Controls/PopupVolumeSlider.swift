//
//  PopupVolumeSlider.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/25/24.
//

import SwiftUI
import JunoUI

struct PopupVolumeSlider: View {
    @State private var isPresented = true
    @State private var buttonSize = CGSize.zero
    @State private var previousVolume: CGFloat

    @State private var interactionTimer: Timer?

    let volume: Binding<CGFloat>
    let isActive: Binding<Bool>?

    init(volume: Binding<CGFloat>, isActive: Binding<Bool>? = nil) {
        self.volume = volume
        self.isActive = isActive
        self.previousVolume = volume.wrappedValue
    }

    var body: some View {
        VStack {
            CircleBackgroundLessButton(systemName: Icon.volume, variableValue: self.volume.wrappedValue, tooltip: "Volume") {
            }
            .background {
                GeometryReader { geometry in
                    // Need a placeholder to take the size of the parent view
                    Color.clear
                        .onAppear {
                            self.buttonSize = geometry.size
                        }
                }
            }
            .overlay(alignment: .trailing) {
                // TODO: Animation is broken with button snapping to the left side
                HStack {
                    HStack {
                        JunoSlider(sliderValue: self.volume, maxSliderValue: 1.0, baseHeight: 10.0, expandedHeight: 22.0, label: "Volume") { editingChanged in
                            if editingChanged {
                                self.interactionTimer?.invalidate()
                                self.interactionTimer = nil
                            }
                        }
                        .frame(width: 150)
                    }
                    // A bug in JunoSlider prevents it from having a dynamic width
                    .frame(width: self.isPresented ? 150 : 0)
                    CircleBackgroundLessButton(
                        systemName: self.volume.wrappedValue > 0 ?  Icon.volume : Icon.mute,
                        variableValue: self.volume.wrappedValue,
                        tooltip: self.volume.wrappedValue > 0 ? "Mute" : "Unmute") {
                        self.interactionTimer?.invalidate()
                        self.interactionTimer = nil
                        
                        if self.volume.wrappedValue > 0 {
                            self.previousVolume = self.volume.wrappedValue
                            self.volume.wrappedValue = 0
                        } else {
                            self.volume.wrappedValue = self.previousVolume
                        }
                        
                    }
                    .frame(width: self.buttonSize.width)
                }
                .padding(.leading, 10)
                .glassBackgroundEffect()
                .alignmentGuide(.trailing, computeValue: { $0[.trailing] })
                .opacity(self.isPresented ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.2), value: self.isPresented)
            }
        }
        .onChange(of: self.isPresented, { _, newValue in
            self.isActive?.wrappedValue = newValue
        })
    }
}

#Preview {
    @State var volume: CGFloat = 0.0

    return PopupVolumeSlider(volume: $volume)
}
