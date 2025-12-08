//
//  StreamListWidget.swift
//  WidgetsExtension
//
//  Created by Adam Gastineau on 12/6/25.
//

import SwiftUI
import WidgetKit

import Twitch

struct StreamListWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "StreamListWidget", intent: ChannelPosterConfigurationIntent.self, provider: StreamListTimelineProvider()) { entry in
            StreamListWidgetView(entry: entry)
        }
    }
}

fileprivate struct StreamListTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = StreamListTimelineEntry
    typealias Intent = ChannelPosterConfigurationIntent

    func placeholder(in context: Context) -> Entry {
        StreamListTimelineEntry(date: .now, state: .noData(error: "No data"))
    }

    func snapshot(for configuration: Intent, in context: Context) async -> Entry {
        StreamListTimelineEntry(date: .now, state: .noData(error: "No data"))
    }

    func timeline(for configuration: Intent, in context: Context) async -> Timeline<Entry> {
        // Create AuthController instance - it will read from shared App Group storage
        let authController = AuthController()
        
        let state: Entry.State

        guard let api = authController.status.api() else {
            let entry = StreamListTimelineEntry(date: .now, state: .noData(error: "No auth"))
            return Timeline(entries: [entry], policy: .after(.now.advanced(by: 2 * 60)))
        }

        let streams: [Twitch.Stream]

        do {
            (streams, _) = try await api.helix(endpoint: .getStreams(limit: 20))
        } catch {
            let entry = StreamListTimelineEntry(date: .now, state: .noData(error: "Could not fetch"))
            return Timeline(entries: [entry], policy: .after(.now.advanced(by: 2 * 60)))
        }

        let entry = StreamListTimelineEntry(date: .now, state: .streams(streams))
        return Timeline(entries: [entry], policy: .after(.now.advanced(by: 2 * 60)))
    }
}

fileprivate struct StreamListTimelineEntry: TimelineEntry {
    var date: Date
    var state: State

    enum State {
        case streams([Twitch.Stream])
        case noData(error: String)
    }
}

fileprivate struct StreamListWidgetView: View {
    let entry: StreamListTimelineEntry
    
    var body: some View {
        switch entry.state {
        case .streams(let streams):
            VStack(alignment: .leading) {
                Text("Live Streams")
                    .font(.headline)

                ForEach(streams.prefix(6)) { stream in
                    HStack {
                        Text(stream.userName)
                            .font(.caption)
                        Spacer()
                        Text("\(stream.viewerCount)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .containerBackground(.fill.tertiary, for: .widget)
        case .noData(let error):
            VStack {
                Image(systemName: "exclamationmark.triangle")
                Text(error)
                    .font(.caption)
            }
            .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}
