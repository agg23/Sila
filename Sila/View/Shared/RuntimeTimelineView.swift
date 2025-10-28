//
//  RuntimeTimelineView.swift
//  Sila
//
//  Created by Adam Gastineau on 10/27/25.
//

import SwiftUI

struct RuntimeTimelineView: View {
    @AppStorage(Setting.disableIncrementingStreamDuration) var disableIncrementingStreamDuration: Bool = false

    @State private var initialRenderDate = Date.now

    let timestamp: Date

    var body: some View {
        if self.disableIncrementingStreamDuration {
            self.runtime(self.initialRenderDate)
        } else {
            TimelineView(.periodic(from: self.initialRenderDate, by: 1.0)) { context in
                self.runtime(context.date)
            }
        }
    }

    @ViewBuilder
    func runtime(_ date: Date) -> some View {
        Text(self.buildRuntimeTimestamp(date))
            .monospacedDigit()
            .lineLimit(1)
    }

    func buildRuntimeTimestamp(_ date: Date) -> String {
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: self.timestamp, to: date)

        // Format the time interval as a string
        return RuntimeFormatter.shared.string(from: components) ?? ""
    }
}
