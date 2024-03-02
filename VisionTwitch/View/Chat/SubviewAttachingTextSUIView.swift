//
//  SubviewAttachingTextSUIView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 3/1/24.
//

import UIKit
import SwiftUI
import SubviewAttachingTextView

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
