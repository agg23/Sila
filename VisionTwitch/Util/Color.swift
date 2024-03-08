//
//  Color.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 3/7/24.
//

import UIKit

extension UIColor {
    // Taken from https://stackoverflow.com/a/27203691
    static func hexStringToUIColor(hex: String, defaultColor: UIColor = .white) -> UIColor {
        var cString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return defaultColor
        }

        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}
