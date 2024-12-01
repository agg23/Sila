//
//  PlayerDurationSliderView.swift
//  Sila
//
//  Created by Adam Gastineau on 12/1/24.
//

import SwiftUI
import JunoUI

struct PlayerDurationSliderView: View {
    let hourFormatter: DateComponentsFormatter
    let minuteFormatter: DateComponentsFormatter

    var currentTime: Binding<CGFloat>
    var duration: Binding<CGFloat>

    @State private var interactionTimer: Timer?

    let isActive: Binding<Bool>

    init(currentTime: Binding<CGFloat>, duration: Binding<CGFloat>, isActive: Binding<Bool>) {
        self.currentTime = currentTime
        self.duration = duration
        self.isActive = isActive

        self.hourFormatter = DateComponentsFormatter()
        self.hourFormatter.allowedUnits = [.hour, .minute, .second]
        self.hourFormatter.unitsStyle = .positional
        self.hourFormatter.zeroFormattingBehavior = .pad

        self.minuteFormatter = DateComponentsFormatter()
        self.minuteFormatter.allowedUnits = [.minute, .second]
        self.minuteFormatter.unitsStyle = .positional
        self.minuteFormatter.zeroFormattingBehavior = .pad
    }

    var body: some View {
        let useHours = self.duration.wrappedValue / (60 * 60) >= 1

        HStack {
            Text(self.format(time: self.currentTime.wrappedValue, usingHours: useHours))
                .monospacedDigit()
                .multilineTextAlignment(.trailing)

            JunoSlider(sliderValue: self.currentTime, maxSliderValue: self.duration.wrappedValue, label: "Current time") { editingChanged in
                self.isActive.wrappedValue = true

                if editingChanged {
                    self.interactionTimer?.invalidate()
                    self.interactionTimer = nil
                } else {
                    self.resetTimer()
                }
            }
            .padding(.horizontal)

            Text(self.format(time: self.duration.wrappedValue, usingHours: useHours))
                .monospacedDigit()
                .multilineTextAlignment(.leading)
        }
    }

    func format(time: CGFloat, usingHours: Bool) -> String {
        if usingHours {
            return self.hourFormatter.string(from: TimeInterval(time)) ?? "0:00"
        } else {
            return self.minuteFormatter.string(from: TimeInterval(time)) ?? "0:00"
        }
    }

    func resetTimer() {
        self.interactionTimer?.invalidate()
        self.interactionTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { _ in
            self.isActive.wrappedValue = false
        })
    }
}

#Preview("Minutes") {
    PlayerDurationSliderView(currentTime: .constant(10), duration: .constant(100), isActive: .constant(false))
}

#Preview("Hours") {
    PlayerDurationSliderView(currentTime: .constant(10), duration: .constant(10000), isActive: .constant(false))
}
