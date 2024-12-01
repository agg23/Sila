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

    init(currentTime: Binding<CGFloat>, duration: Binding<CGFloat>) {
        self.currentTime = currentTime
        self.duration = duration

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

            JunoSlider(sliderValue: self.currentTime, maxSliderValue: self.duration.wrappedValue, label: "")
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
}

#Preview("Minutes") {
    PlayerDurationSliderView(currentTime: .constant(10), duration: .constant(100))
}

#Preview("Hours") {
    PlayerDurationSliderView(currentTime: .constant(10), duration: .constant(10000))
}
