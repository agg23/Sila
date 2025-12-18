//
//  FollowerImmersiveView.swift
//  Sila
//
//  Created by Adam Gastineau on 12/15/25.
//

import SwiftUI
import RealityKit

struct FollowerImmersiveView: View {
    let streamableVideo: StreamableVideo

    @State private var playerModel: WebViewPlayer? = nil

    var contentId: String {
        PlaybackPresentableController.contentId(for: self.streamableVideo)
    }

    var body: some View {
        VStack {
            if let playerModel = self.playerModel {
                FollowerImmersiveRealityView(playerModel: playerModel, streamableVideo: self.streamableVideo)
            }
        }
        .presentableTracking(contentId: self.contentId, role: .standalone, factory: {
            PlaybackPresentableController(contentId: self.contentId, model: WebViewPlayer())
        }) { (controller: PlaybackPresentableController) in
            self.playerModel = controller.model
        }
    }
}

private struct FollowerImmersiveRealityView: View {
    @Bindable var playerModel: WebViewPlayer

    let streamableVideo: StreamableVideo

    @State var windowPositionAnchor: AnchorEntity?

    var body: some View {
        // Grab a reference to the window transform so we can rerender RealityView
//        let _ = self.playerModel.windowTransform

        RealityView { content, attachments in
            let anchor = AnchorEntity(.head, trackingMode: .continuous)
            anchor.transform = Transform.topRight

            content.add(anchor)
            self.windowPositionAnchor = anchor

            self.assignAttachment(anchor: anchor, attachments: attachments)
        } update: { content, attachments in
//            if let headAnchor = self.windowPositionAnchor {
//                guard self.model.windowTransform != headAnchor.transform else {
//                    return
//                }
//
//                headAnchor.move(to: self.model.windowTransform, relativeTo: nil, duration: 0.5)
//            }
        } attachments: {
            Attachment(id: "window") {
//                FollowerWindowView(model: self.model)
                TwitchVideoView(controlVisibility: .constant(.hidden), streamableVideo: self.streamableVideo, delayLoading: false, player: self.playerModel)
            }
        }
    }

    func assignAttachment(anchor: AnchorEntity, attachments: RealityViewAttachments) {
        guard let attachment = attachments.entity(for: "window") else {
            print("Could not find attachment")
            return
        }

        attachment.components.set(BillboardComponent())

        anchor.addChild(attachment)
    }
}

extension Transform {
    private static let windowZDepth: Float = -1.7
    private static let xOffset: Float = 0.5
    private static let yOffset: Float = 0.25

    static let topLeft = Transform(translation: .init(x: -xOffset, y: yOffset, z: windowZDepth))
    static let topRight = Transform(translation: .init(x: xOffset, y: yOffset, z: windowZDepth))
    static let bottomLeft = Transform(translation: .init(x: -xOffset, y: -yOffset, z: windowZDepth))
    static let bottomRight = Transform(translation: .init(x: xOffset, y: -yOffset, z: windowZDepth))
}
