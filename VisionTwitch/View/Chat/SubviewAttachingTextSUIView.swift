//
//  SubviewAttachingTextSUIView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 3/1/24.
//

import UIKit
import SwiftUI
import SubviewAttachingTextView
import TwitchIRC

struct SubviewAttachingTextSUIView: UIViewRepresentable {
    let attributedString: NSAttributedString

    func makeUIView(context: Context) -> WrapperView {
        WrapperView()
    }

    func updateUIView(_ view: WrapperView, context: Context) {
        view.attributedText = self.attributedString
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: WrapperView, context: Context) -> CGSize? {
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

struct EmoteTextView: UIViewRepresentable {
    let message: PrivateMessage

    func makeUIView(context: Context) -> WrapperView {
        WrapperView()
    }

    func makeCoordinator() -> EmoteTextCoordinator {
        Coordinator(message: self.message)
    }

    func updateUIView(_ view: WrapperView, context: Context) {
        context.coordinator.update(message: self.message)

        view.attributedText = context.coordinator.attributedString
    }
}

extension EmoteTextView {
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: WrapperView, context: Context) -> CGSize? {
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

private func createAttachmentString(using emote: Emote) -> NSAttributedString {
    let imageView = ImageView(frame: .init(x: 0, y: 0, width: 28, height: 28))
    imageView.setImage(with: URL(string: emoteUrl(from: emote.id))!)
    let attachment = SubviewTextAttachment(view: imageView)

    return NSAttributedString(attachment: attachment)
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

class WrapperView: SubviewAttachingTextView {
//    let textView: SubviewAttachingTextView

//    var attributedText: NSAttributedString {
//        get {
//            self.textView.attributedText
//        }
//        set {
//            self.textView.attributedText = newValue
//            self.invalidateIntrinsicContentSize()
//            self.textView.frame = CGRect(origin: .zero, size: self.intrinsicContentSize)
//        }
//    }

//    override init(frame: CGRect) {
//        self.textView = SubviewAttachingTextView()
//        self.textView.isEditable = false
//        self.textView.isScrollEnabled = false
//        self.textView.backgroundColor = .green
//
//        super.init(frame: frame)
//
//        self.translatesAutoresizingMaskIntoConstraints = false
//        self.setContentHuggingPriority(.defaultHigh, for: .horizontal)
//        self.setContentHuggingPriority(.defaultHigh, for: .vertical)
//
//        self.backgroundColor = .blue
//
//        self.addSubview(self.textView)
//    }
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

        self.isEditable = false
        self.isScrollEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//    override var intrinsicContentSize: CGSize {
//        let boundingRect = self.attributedText.boundingRect(with: CGSize(width: self.textContainer.size.width, height: .greatestFiniteMagnitude), context: nil)
//        return boundingRect.size
//    }
}

#Preview {
    EmoteTextView(message: PrivateMessage(channel: "mistermv", chatColor: "#1E90FF", userDisplayName: "damasenpai", message: "claraqDISCO claraqDISCO claraqDISCO claraqDISCO claraqDISCO", emotes: "emotesv2_b01874d1da9f479aa49df41c48164233:0-10,12-22,24-34,36-46,48-58"))
}
