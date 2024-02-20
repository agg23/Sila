//
//  ChannelView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/19/24.
//

import SwiftUI

struct ChannelView: View {
    @State private var liveProvider: DataProvider<Bool, Error>?

    let channel: UserWrapper

    var body: some View {
        let user = self.channel.user

        VStack {
            HStack {
                profileImage
                VStack {
                    Text(user.displayName)
                        .font(.title)
                        .lineLimit(1, reservesSpace: true)

                    let liveButton = Button {

                    } label: {
                        Text("Watch Now")
                    }

                    let offlineMessage = Text("Offline")

                    SuccessDataView(taskClosure: { api in
                        return Task {
                            let (streams, _) = try await api.getStreams(userIDs: [user.id])
                            return streams.count > 0
                        }
                    }, content: { isLive in
                        if isLive {
                            liveButton
                        } else {
                            offlineMessage
                        }
                    }, other: {
                        offlineMessage
                    }, requiresAuth: false, runOnAppear: true)
                }
            }
        }
        .onAppear {
            // This will trigger on every appear, refetching
            liveProvider = DataProvider(taskClosure: { api in
                Task {
                    let (streams, _) = try await api.getStreams(userIDs: [user.id])
                    return streams.count > 0
                }
            }, requiresAuth: false)
        }
    }

    var profileImage: some View {
        AsyncImage(url: URL(string: self.channel.user.profileImageUrl), content: { image in
            image
                .resizable()
        }, placeholder: {
            // Make sure ProgressView is the same size as the final image will be
            GeometryReader { geometry in
                ProgressView()
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        })
        .aspectRatio(1.0, contentMode: .fit)
        .frame(width: 150)
    }
}

#Preview {
    ChannelView(channel: UserWrapper(user: USER_MOCK()))
}
