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

    func makeUIView(context: Context) -> SubviewAttachingTextView {
        SubviewAttachingTextView()
    }

    func updateUIView(_ view: SubviewAttachingTextView, context: Context) {
        view.attributedText = self.attributedString
    }
}
