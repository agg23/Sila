//
//  AttributedString.swift
//  Sila
//
//  Created by Adam Gastineau on 11/14/25.
//

import Foundation
import UIKit

struct AttributedStringBuilder {
    static let shared = AttributedStringBuilder()

    private let dataDetector: NSDataDetector

    init() {
        self.dataDetector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    }

    func buildLinkString(from string: String) -> AttributedString {
        let attributedString = NSMutableAttributedString(string: string)

        let matches = self.dataDetector.matches(in: string, range: .init(location: 0, length: string.utf16.count))
        for match in matches {
            guard match.resultType == .link, let url = match.url else {
                continue
            }

            attributedString.addAttribute(.link, value: url, range: match.range)

            attributedString.addAttribute(.foregroundColor, value: UIColor.twitchLinkPurple, range: match.range)
        }

        return AttributedString(attributedString)
    }
}
