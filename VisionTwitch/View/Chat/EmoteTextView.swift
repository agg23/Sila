//
//  EmoteTextView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 3/1/24.
//

import UIKit
import SwiftUI
import SubviewAttachingTextView
import TwitchIRC

struct EmoteTextView: UIViewRepresentable {
    let message: PrivateMessage

    func makeUIView(context: Context) -> EmoteUITextView {
        EmoteUITextView()
    }

    func makeCoordinator() -> EmoteTextCoordinator {
        Coordinator(message: self.message)
    }

    func updateUIView(_ view: EmoteUITextView, context: Context) {
        context.coordinator.update(message: self.message)

        view.attributedText = context.coordinator.attributedString
    }
}

extension EmoteTextView {
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: EmoteUITextView, context: Context) -> CGSize? {
        let dimensions = proposal.replacingUnspecifiedDimensions(
            by: .init(
                width: 0,
                height: CGFloat.greatestFiniteMagnitude
            )
        )

        let calculatedHeight = calculateTextViewHeight(
            containerSize: dimensions,
            attributedString: uiView.attributedText
        )

        return .init(
            width: dimensions.width,
            height: calculatedHeight
        )
    }

    private func calculateTextViewHeight(containerSize: CGSize,
                                         attributedString: NSAttributedString) -> CGFloat {
        let boundingRect = attributedString.boundingRect(
            with: .init(width: containerSize.width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )

        return boundingRect.height
    }
}

private func buildString(from message: PrivateMessage) -> NSAttributedString {
    let attributedString = NSMutableAttributedString(string: message.message)

    var removedCharCount = 0

    var emotes = message.parseEmotes()

    // Sometimes emotes can be out of order
    emotes.sort { a, b in
        a.startIndex < b.startIndex
    }

    for emote in emotes {
        let attachmentString = createAttachmentString(using: emote)

        let length = emote.endIndex - emote.startIndex + 1

        attributedString.replaceCharacters(in: .init(location: emote.startIndex - removedCharCount, length: length), with: attachmentString)

        // Substring is replaced by a single character, make sure to include that
        removedCharCount += length - 1
    }

    return attributedString
}

private func createAttachmentString(using emote: Emote) -> NSAttributedString {
    let imageView = ImageView(frame: .init(x: 0, y: 0, width: 28, height: 28))
    imageView.setImage(with: URL(string: emoteUrl(from: emote.id))!)
    let attachment = SubviewTextAttachment(view: imageView)

    return NSAttributedString(attachment: attachment)
}

private func emoteUrl(from id: String) -> String {
    "https://static-cdn.jtvnw.net/emoticons/v2/\(id)/default/light/1.0"
}

class EmoteTextCoordinator: NSObject {
    private var message: PrivateMessage

    private(set) var attributedString: NSAttributedString

    init(message: PrivateMessage) {
        self.message = message
        self.attributedString = buildString(from: message)
    }

    func update(message: PrivateMessage) {
        guard message.id != self.message.id else {
            // Same message, nothing to do
            return
        }

        self.attributedString = buildString(from: message)
    }
}

class EmoteUITextView: SubviewAttachingTextView {
    override var attributedText: NSAttributedString! {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }

    init() {
        // TODO: Probable initial render perf gains if we could figure out how to start in TextKit 1 mode
        // The static init(usingTextLayoutManager:)
        super.init(frame: .zero, textContainer: nil)

        self.textContainer.lineFragmentPadding = 0
        self.textContainerInset = .zero
        self.textColor = .white

        self.isEditable = false
        self.isScrollEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#Preview {
    EmoteTextView(message: PrivateMessage(channel: "mistermv", chatColor: "#1E90FF", userDisplayName: "damasenpai", message: "claraqDISCO claraqDISCO claraqDISCO claraqDISCO claraqDISCO", emotes: "emotesv2_b01874d1da9f479aa49df41c48164233:0-10,12-22,24-34,36-46,48-58"))
}
